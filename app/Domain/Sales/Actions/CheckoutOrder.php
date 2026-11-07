<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Crm\Models\Customer;
use App\Domain\Memberships\Actions\UseMembershipWash;
use App\Domain\Orders\Actions\ChangeOrderStatus;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Orders\Models\OrderItem;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Sales\Enums\PaymentMethod;
use App\Domain\Sales\Enums\PointTransactionType;
use App\Domain\Sales\Models\CashShift;
use App\Domain\Sales\Models\Invoice;
use App\Domain\Sales\Support\PointsLedger;
use App\Domain\Sales\Support\Vat;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Takes payment for an order at the till: applies a discount within the cashier's limit, works out
 * the VAT from the car wash's settings, issues the invoice with the branch's next number and records
 * the payment on the cashier's open shift at the branch. With `deliver`, a ready car is handed
 * over in the same step. With points on, a registered customer earns points on what they paid, and can spend
 * points for money off instead of a discount. A wash can also be taken from a membership the customer bought.
 */
class CheckoutOrder
{
    public function __construct(private ChangeOrderStatus $changeOrderStatus, private AuditTrail $auditTrail, private PointsLedger $pointsLedger, private UseMembershipWash $useMembershipWash) {}

    /**
     * @param  array{discount_amount?: ?int, discount_percent_bps?: ?int, discount_reason?: ?string, method?: string, tendered?: ?int, deliver?: bool, redeem_points?: ?int, membership_id?: ?string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, Order $order, array $data): Order
    {
        return DB::transaction(function () use ($actor, $order, $data): Order {
            $order = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();
            $this->ensurePayable($order);

            $subtotal = (int) $order->items()->sum('line_total');
            $tenant = $actor->tenant;
            $redeemed = (int) ($data['redeem_points'] ?? 0);
            $pointsHolder = $tenant->points_enabled && $order->customer_id !== null
                ? Customer::query()->whereKey($order->customer_id)->lockForUpdate()->first()
                : null;
            $membership = null;
            if (filled($data['membership_id'] ?? null)) {
                ['membership' => $membership, 'price' => $discount] = $this->useMembershipWash->handle($tenant, $order, $data['membership_id'], $data);
            } else {
                $discount = $redeemed > 0 ? $this->pointsDiscount($tenant, $pointsHolder, $subtotal, $redeemed, $data) : $this->discount($actor, $subtotal, $data);
            }
            $vat = Vat::of($subtotal - $discount, $tenant->vat_rate_bps, $tenant->prices_include_vat);
            $earned = $pointsHolder === null ? 0 : intdiv($vat['total'], $tenant->points_earn_amount);
            $method = PaymentMethod::tryFrom($data['method'] ?? '') ?? PaymentMethod::Cash;
            $tendered = $method === PaymentMethod::Cash ? ($data['tendered'] ?? $vat['total']) : null;

            if ($tendered !== null && $tendered < $vat['total']) {
                throw ValidationException::withMessages(['tendered' => __('The cash received is less than the total.')]);
            }

            $branch = Branch::query()->whereKey($order->branch_id)->lockForUpdate()->firstOrFail();
            $shift = CashShift::openFor($actor, $branch)
                ?? throw ValidationException::withMessages(['shift' => __('Open your shift before taking payment.')]);

            $invoice = new Invoice;
            $invoice->forceFill([
                'branch_id' => $order->branch_id,
                'number' => (Invoice::query()->where('branch_id', $order->branch_id)->max('number') ?? 0) + 1,
                'order_id' => $order->id,
                'customer_id' => $order->customer_id,
                'subtotal' => $subtotal,
                'discount_total' => $discount,
                'discount_reason' => match (true) {
                    $discount === 0 => null,
                    $membership !== null => __('Membership: :name', ['name' => $membership->name]),
                    $redeemed > 0 => __('Paid with :points points', ['points' => $redeemed]),
                    default => $data['discount_reason'],
                },
                'customer_membership_id' => $membership?->id,
                'points_redeemed' => $redeemed,
                'points_earned' => $earned,
                'total' => $vat['total'],
                'vat_rate_bps' => $tenant->vat_rate_bps,
                'prices_include_vat' => $tenant->prices_include_vat,
                'vat_amount' => $vat['vat'],
                'issued_by' => $actor->id,
                'issued_at' => now(),
            ])->save();

            $invoice->lines()->createMany($order->items->whereNull('parent_id')->map(fn (OrderItem $item) => [
                'service_id' => $item->service_id,
                'name' => $item->name,
                'quantity' => $item->quantity,
                'unit_price' => $item->unit_price,
                'line_total' => $item->line_total,
            ])->all());

            $invoice->payments()->create([
                'branch_id' => $order->branch_id,
                'cash_shift_id' => $shift->id,
                'method' => $method,
                'amount' => $vat['total'],
                'tendered' => $tendered,
                'change_given' => $tendered === null ? 0 : $tendered - $vat['total'],
                'received_by' => $actor->id,
                'received_at' => now(),
            ]);

            $membership?->increment('washes_used');

            if ($pointsHolder !== null) {
                if ($redeemed > 0) {
                    $this->pointsLedger->move($pointsHolder, PointTransactionType::Redeemed, -$redeemed, $order->branch_id, $actor, $invoice->id);
                }

                if ($earned > 0) {
                    $this->pointsLedger->move($pointsHolder, PointTransactionType::Earned, $earned, $order->branch_id, $actor, $invoice->id);
                }

                $order->setRelation('customer', $pointsHolder);
            }

            $this->auditTrail->record('invoice.issued', $invoice, $actor, 'Order paid', [
                'order_id' => $order->id,
                'total' => $invoice->total,
                'discount' => $discount,
                'discount_reason' => $invoice->discount_reason,
                'points_redeemed' => $redeemed,
                'points_earned' => $earned,
            ]);

            $order->setRelation('invoice', $invoice);

            if (($data['deliver'] ?? false) && $order->status === OrderStatus::Ready) {
                $this->changeOrderStatus->handle($actor, $order, OrderStatus::Delivered);
            }

            return $order;
        });
    }

    /**
     * @throws ValidationException
     */
    private function ensurePayable(Order $order): void
    {
        if ($order->status === OrderStatus::Cancelled) {
            throw ValidationException::withMessages(['order' => __('A cancelled order cannot be paid.')]);
        }

        if ($order->isPaid()) {
            throw ValidationException::withMessages(['order' => __('This order is already paid.')]);
        }
    }

    /**
     * What the points take off. They are spent in whole steps of the owner's rate, never for more than the order
     * is worth, and not on top of another discount.
     *
     * @param  array{discount_amount?: ?int, discount_percent_bps?: ?int}  $data
     *
     * @throws ValidationException
     */
    private function pointsDiscount(Tenant $tenant, ?Customer $pointsHolder, int $subtotal, int $redeemed, array $data): int
    {
        if (! $tenant->points_enabled) {
            throw ValidationException::withMessages(['points' => __('The points system is turned off.')]);
        }

        if ($pointsHolder === null) {
            throw ValidationException::withMessages(['points' => __('Only a registered customer has points.')]);
        }

        if (! empty($data['discount_amount']) || ! empty($data['discount_percent_bps'])) {
            throw ValidationException::withMessages(['points' => __('Points cannot be combined with a discount.')]);
        }

        if ($redeemed > $pointsHolder->points_balance) {
            throw ValidationException::withMessages(['points' => __('This customer does not have that many points.')]);
        }

        if ($redeemed % $tenant->points_redeem_points !== 0) {
            throw ValidationException::withMessages(['points' => __('Points are spent in steps of :points.', ['points' => $tenant->points_redeem_points])]);
        }

        $discount = intdiv($redeemed, $tenant->points_redeem_points) * $tenant->points_redeem_value;

        if ($discount > $subtotal) {
            throw ValidationException::withMessages(['points' => __('These points are worth more than the order.')]);
        }

        return $discount;
    }

    /**
     * The discount in minor units, given as an amount or a percentage, within the actor's limit.
     *
     * @param  array{discount_amount?: ?int, discount_percent_bps?: ?int, discount_reason?: ?string}  $data
     *
     * @throws ValidationException
     */
    private function discount(User $actor, int $subtotal, array $data): int
    {
        $discount = isset($data['discount_percent_bps'])
            ? intdiv(2 * $subtotal * $data['discount_percent_bps'] + 10000, 20000)
            : (int) ($data['discount_amount'] ?? 0);

        if ($discount === 0) {
            return 0;
        }

        if ($discount > $subtotal) {
            throw ValidationException::withMessages(['discount_amount' => __('The discount cannot be more than the total.')]);
        }

        $limit = $actor->maxDiscountBps();

        if ($discount * 10000 > $subtotal * $limit) {
            throw ValidationException::withMessages([
                'discount_amount' => $limit === 0
                    ? __('You are not allowed to give discounts.')
                    : __('Your discount limit is :limit%.', ['limit' => $limit / 100]),
            ]);
        }

        if (blank($data['discount_reason'] ?? null)) {
            throw ValidationException::withMessages(['discount_reason' => __('Give a reason for the discount.')]);
        }

        return $discount;
    }
}
