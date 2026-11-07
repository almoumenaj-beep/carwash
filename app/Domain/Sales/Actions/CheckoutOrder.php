<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Crm\Models\Customer;
use App\Domain\Orders\Actions\ChangeOrderStatus;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Orders\Models\OrderItem;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Sales\Enums\PaymentMethod;
use App\Domain\Sales\Models\CashShift;
use App\Domain\Sales\Models\Invoice;
use App\Domain\Sales\Support\Vat;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Takes payment for an order at the till: applies a discount within the cashier's limit, works out
 * the VAT from the car wash's settings, issues the invoice with the branch's next number and records
 * the payment on the cashier's open shift at the branch. With `deliver`, a ready car is handed
 * over in the same step. With the loyalty card on, a registered customer earns a stamp for the visit, or
 * spends their stamps on a free wash instead.
 */
class CheckoutOrder
{
    public function __construct(private ChangeOrderStatus $changeOrderStatus, private AuditTrail $auditTrail) {}

    /**
     * @param  array{discount_amount?: ?int, discount_percent_bps?: ?int, discount_reason?: ?string, method?: string, tendered?: ?int, deliver?: bool, use_loyalty_reward?: bool}  $data
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
            $useReward = (bool) ($data['use_loyalty_reward'] ?? false);
            $cardHolder = $tenant->loyalty_enabled && $order->customer_id !== null
                ? Customer::query()->whereKey($order->customer_id)->lockForUpdate()->first()
                : null;
            $discount = $useReward ? $this->freeWash($tenant, $order, $cardHolder, $data) : $this->discount($actor, $subtotal, $data);
            $vat = Vat::of($subtotal - $discount, $tenant->vat_rate_bps, $tenant->prices_include_vat);
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
                'discount_reason' => $discount === 0 ? null : ($useReward ? __('Loyalty card: free wash') : $data['discount_reason']),
                'loyalty_reward' => $useReward,
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

            if ($cardHolder !== null) {
                $cardHolder->forceFill([
                    'loyalty_stamps' => $useReward ? $cardHolder->loyalty_stamps - $tenant->loyalty_washes_required : $cardHolder->loyalty_stamps + 1,
                ])->save();
                $order->setRelation('customer', $cardHolder);
            }

            $this->auditTrail->record('invoice.issued', $invoice, $actor, 'Order paid', [
                'order_id' => $order->id,
                'total' => $invoice->total,
                'discount' => $discount,
                'discount_reason' => $invoice->discount_reason,
                'loyalty_reward' => $useReward,
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
     * What the free wash takes off: one of the order's cheapest wash services. Add-ons are still paid for, and a
     * package is not a wash, so it is not covered.
     *
     * @param  array{discount_amount?: ?int, discount_percent_bps?: ?int}  $data
     *
     * @throws ValidationException
     */
    private function freeWash(Tenant $tenant, Order $order, ?Customer $cardHolder, array $data): int
    {
        if (! $tenant->loyalty_enabled) {
            throw ValidationException::withMessages(['loyalty' => __('The loyalty card is turned off.')]);
        }

        if ($cardHolder === null) {
            throw ValidationException::withMessages(['loyalty' => __('Only a registered customer has a loyalty card.')]);
        }

        if ($cardHolder->loyalty_stamps < $tenant->loyalty_washes_required) {
            throw ValidationException::withMessages(['loyalty' => __('This customer has not earned a free wash yet.')]);
        }

        if (! empty($data['discount_amount']) || ! empty($data['discount_percent_bps'])) {
            throw ValidationException::withMessages(['loyalty' => __('A free wash cannot be combined with a discount.')]);
        }

        $price = $order->items()
            ->whereNull('parent_id')
            ->where('is_addon', false)
            ->where('is_package', false)
            ->where('unit_price', '>', 0)
            ->min('unit_price');

        return $price === null
            ? throw ValidationException::withMessages(['loyalty' => __('This order has no wash for the free wash to cover.')])
            : (int) $price;
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
