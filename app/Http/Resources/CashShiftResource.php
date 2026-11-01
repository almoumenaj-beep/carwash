<?php

namespace App\Http\Resources;

use App\Domain\Sales\Models\CashShift;
use App\Domain\Sales\Models\Invoice;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A shift with its till summary. Amounts are in minor units; `expected_cash` is live while the shift
 * is open, and `variance` (counted - expected, negative when short) is set once it is closed.
 *
 * @mixin CashShift
 */
class CashShiftResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $invoices = Invoice::query()->whereIn('id', $this->payments()->select('invoice_id'));

        return [
            'id' => $this->id,
            'branch_id' => $this->branch_id,
            'is_open' => $this->isOpen(),
            'opened_by' => ['id' => $this->opener->id, 'name' => $this->opener->name],
            'opened_at' => $this->opened_at->toIso8601String(),
            'opening_float' => $this->opening_float,
            'invoices_count' => (clone $invoices)->count(),
            'discounts_total' => (int) (clone $invoices)->sum('discount_total'),
            'vat_total' => (int) (clone $invoices)->sum('vat_amount'),
            'cash_taken' => $this->cashTaken(),
            'expected_cash' => $this->expected_cash ?? $this->expectedCash(),
            'counted_cash' => $this->counted_cash,
            'variance' => $this->variance,
            'close_note' => $this->close_note,
            'closed_by' => $this->closer === null ? null : ['id' => $this->closer->id, 'name' => $this->closer->name],
            'closed_at' => $this->closed_at?->toIso8601String(),
        ];
    }
}
