<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Crm\Models\Customer;
use App\Domain\Memberships\Models\CustomerMembership;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Domain\Sales\Enums\PaymentMethod;
use App\Domain\Sales\Enums\PointTransactionType;
use App\Domain\Sales\Models\CashShift;
use App\Domain\Sales\Models\Invoice;
use App\Domain\Sales\Models\Payment;
use App\Domain\Sales\Models\Refund;
use App\Domain\Sales\Support\PointsLedger;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Gives back a whole invoice, by the way it was paid: from the shift that took the money while it is still open,
 * since that is the drawer holding it, otherwise from the staff member's own open shift. The invoice stays on
 * record marked as refunded and the money is counted on the day it was given. The order becomes unpaid again, so
 * it can be collected again or cancelled. Points move back, leaving no less than zero if the customer already
 * spent what they earned; a wash from a membership returns to it; and a membership sold by this invoice stops,
 * unless washes were taken from it.
 */
class RefundInvoice
{
    public function __construct(private PointsLedger $pointsLedger, private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Invoice $invoice, string $reason): Invoice
    {
        return DB::transaction(function () use ($actor, $invoice, $reason): Invoice {
            $invoice = Invoice::query()->whereKey($invoice->getKey())->lockForUpdate()->firstOrFail();

            if ($invoice->refunded_at !== null) {
                throw ValidationException::withMessages(['invoice' => __('This invoice is already refunded.')]);
            }

            $this->stopMembershipItSold($actor, $invoice);

            $payment = $invoice->payments()->firstOrFail();
            $shift = $invoice->total > 0 ? $this->shift($actor, $invoice, $payment) : null;

            $refund = new Refund;
            $refund->forceFill([
                'invoice_id' => $invoice->id,
                'branch_id' => $invoice->branch_id,
                'cash_shift_id' => $shift?->id,
                'method' => $payment->method,
                'amount' => $invoice->total,
                'vat_amount' => $invoice->vat_amount,
                'reason' => $reason,
                'created_by' => $actor->id,
            ])->save();

            $invoice->forceFill(['refunded_at' => now()])->save();

            $this->returnPoints($actor, $invoice);
            $this->returnMembershipWash($invoice);

            $this->auditTrail->record('invoice.refunded', $invoice, $actor, 'Invoice refunded', [
                'amount' => $invoice->total,
                'method' => $payment->method->value,
                'reason' => $reason,
            ]);

            return $invoice;
        });
    }

    /**
     * @throws ValidationException
     */
    private function shift(User $actor, Invoice $invoice, Payment $payment): CashShift
    {
        $original = CashShift::query()->whereKey($payment->cash_shift_id)->lockForUpdate()->first();
        $shift = $original?->isOpen()
            ? $original
            : CashShift::openFor($actor, Branch::query()->findOrFail($invoice->branch_id));

        if ($shift === null) {
            throw ValidationException::withMessages(['shift' => __('Open your shift before giving money back.')]);
        }

        if ($payment->method === PaymentMethod::Cash && $shift->expectedCash() < $invoice->total) {
            throw ValidationException::withMessages(['invoice' => __('There is not enough cash in the drawer for this refund.')]);
        }

        return $shift;
    }

    /**
     * @throws ValidationException
     */
    private function stopMembershipItSold(User $actor, Invoice $invoice): void
    {
        $membership = CustomerMembership::query()->where('invoice_id', $invoice->id)->lockForUpdate()->first();

        if ($membership === null) {
            return;
        }

        if ($membership->washes_used > 0) {
            throw ValidationException::withMessages(['invoice' => __('Washes were already taken from this membership, so it cannot be refunded.')]);
        }

        $membership->forceFill(['cancelled_at' => $membership->cancelled_at ?? now(), 'cancelled_by' => $membership->cancelled_by ?? $actor->id])->save();
    }

    private function returnPoints(User $actor, Invoice $invoice): void
    {
        if ($invoice->customer_id === null || ($invoice->points_earned === 0 && $invoice->points_redeemed === 0)) {
            return;
        }

        $customer = Customer::query()->whereKey($invoice->customer_id)->lockForUpdate()->firstOrFail();
        $afterReturning = $customer->points_balance + $invoice->points_redeemed;
        $change = $invoice->points_redeemed - min($afterReturning, $invoice->points_earned);

        if ($change !== 0) {
            $this->pointsLedger->move($customer, PointTransactionType::Refund, $change, $invoice->branch_id, $actor, $invoice->id);
        }
    }

    private function returnMembershipWash(Invoice $invoice): void
    {
        if ($invoice->customer_membership_id !== null) {
            CustomerMembership::query()->whereKey($invoice->customer_membership_id)->lockForUpdate()->firstOrFail()->decrement('washes_used');
        }
    }
}
