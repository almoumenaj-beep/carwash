<?php

namespace App\Domain\Memberships\Actions;

use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Memberships\Enums\MembershipScope;
use App\Domain\Memberships\Models\CustomerMembership;
use App\Domain\Memberships\Models\MembershipPlan;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Domain\Sales\Enums\PaymentMethod;
use App\Domain\Sales\Enums\PointTransactionType;
use App\Domain\Sales\Models\CashShift;
use App\Domain\Sales\Models\Invoice;
use App\Domain\Sales\Support\PointsLedger;
use App\Domain\Sales\Support\Vat;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Sells a membership at the till, on the cashier's open shift. For now VAT and revenue are taken when it is sold,
 * pending the owner's review of the money rules against local law. The customer earns points on what they paid.
 */
class SellMembership
{
    public function __construct(private PointsLedger $pointsLedger, private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Customer $customer, MembershipPlan $plan, Branch $branch, PaymentMethod $method, ?string $vehicleId): CustomerMembership
    {
        $tenant = $actor->tenant;

        if (! $tenant->memberships_enabled) {
            throw ValidationException::withMessages(['membership' => __('Memberships are turned off.')]);
        }

        if (! $plan->is_active) {
            throw ValidationException::withMessages(['membership_plan_id' => __('This membership is no longer offered.')]);
        }

        $vehicle = $this->vehicle($plan, $customer, $vehicleId);

        return DB::transaction(function () use ($actor, $tenant, $customer, $plan, $branch, $method, $vehicle): CustomerMembership {
            Branch::query()->whereKey($branch->id)->lockForUpdate()->first();
            $shift = CashShift::openFor($actor, $branch)
                ?? throw ValidationException::withMessages(['shift' => __('Open your shift before taking payment.')]);

            $vat = Vat::of($plan->price, $tenant->vat_rate_bps, $tenant->prices_include_vat);
            $earned = $tenant->points_enabled ? intdiv($vat['total'], $tenant->points_earn_amount) : 0;

            $invoice = new Invoice;
            $invoice->forceFill([
                'branch_id' => $branch->id,
                'number' => (Invoice::query()->where('branch_id', $branch->id)->max('number') ?? 0) + 1,
                'customer_id' => $customer->id,
                'subtotal' => $plan->price,
                'discount_total' => 0,
                'total' => $vat['total'],
                'vat_rate_bps' => $tenant->vat_rate_bps,
                'prices_include_vat' => $tenant->prices_include_vat,
                'vat_amount' => $vat['vat'],
                'points_earned' => $earned,
                'issued_by' => $actor->id,
                'issued_at' => now(),
            ])->save();

            $invoice->lines()->create([
                'name' => $plan->name,
                'quantity' => 1,
                'unit_price' => $plan->price,
                'line_total' => $plan->price,
            ]);

            $invoice->payments()->create([
                'branch_id' => $branch->id,
                'cash_shift_id' => $shift->id,
                'method' => $method,
                'amount' => $vat['total'],
                'tendered' => $method === PaymentMethod::Cash ? $vat['total'] : null,
                'change_given' => 0,
                'received_by' => $actor->id,
                'received_at' => now(),
            ]);

            $membership = new CustomerMembership;
            $membership->forceFill([
                'membership_plan_id' => $plan->id,
                'customer_id' => $customer->id,
                'vehicle_id' => $vehicle?->id,
                'invoice_id' => $invoice->id,
                'name' => $plan->name,
                'washes' => $plan->washes,
                'service_ids' => $plan->service_ids,
                'expires_at' => CarbonImmutable::now($tenant->timezone)->addDays($plan->validity_days)->endOfDay()->utc(),
                'sold_by' => $actor->id,
            ])->save();

            if ($earned > 0) {
                $locked = Customer::query()->whereKey($customer->id)->lockForUpdate()->firstOrFail();
                $this->pointsLedger->move($locked, PointTransactionType::Earned, $earned, $branch->id, $actor, $invoice->id);
            }

            $this->auditTrail->record('membership.sold', $membership, $actor, 'Membership sold', [
                'customer_id' => $customer->id,
                'invoice_id' => $invoice->id,
                'total' => $invoice->total,
            ]);

            return $membership;
        });
    }

    /**
     * @throws ValidationException
     */
    private function vehicle(MembershipPlan $plan, Customer $customer, ?string $vehicleId): ?Vehicle
    {
        if ($plan->scope !== MembershipScope::Vehicle) {
            return null;
        }

        return ($vehicleId === null ? null : $customer->vehicles()->whereKey($vehicleId)->first())
            ?? throw ValidationException::withMessages(['vehicle_id' => __('Choose which of the customer\'s cars this membership is for.')]);
    }
}
