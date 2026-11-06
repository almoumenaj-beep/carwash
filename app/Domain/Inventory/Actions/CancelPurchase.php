<?php

namespace App\Domain\Inventory\Actions;

use App\Domain\Expenses\Actions\DeleteExpense;
use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Models\InventoryItem;
use App\Domain\Inventory\Models\Purchase;
use App\Domain\Inventory\Models\PurchaseLine;
use App\Domain\Inventory\Support\StockLedger;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Cancels a purchase recorded by mistake: its quantities leave the branch's stock, its expense is removed, each
 * material's cost returns to the last purchase still standing, and it stays listed as cancelled. Refused once
 * part of it has been used, since the stock no longer holds what would be taken back.
 */
class CancelPurchase
{
    public function __construct(
        private StockLedger $ledger,
        private DeleteExpense $deleteExpense,
        private AuditTrail $auditTrail,
    ) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Purchase $purchase): Purchase
    {
        return DB::transaction(function () use ($actor, $purchase): Purchase {
            $purchase = Purchase::query()->with(['lines', 'expense.cashShift'])->lockForUpdate()->findOrFail($purchase->id);

            if ($purchase->isCancelled()) {
                throw ValidationException::withMessages(['purchase' => __('This purchase was already cancelled.')]);
            }

            foreach ($purchase->lines->sortBy('inventory_item_id') as $line) {
                $this->takeBack($actor, $purchase, $line);
            }

            if ($purchase->expense !== null) {
                $this->deleteExpense->remove($actor, $purchase->expense);
            }

            $purchase->forceFill(['cancelled_at' => now(), 'cancelled_by' => $actor->id, 'expense_id' => null])->save();

            $this->auditTrail->record('purchase.cancelled', $purchase, $actor, 'Purchase cancelled', ['total' => $purchase->total]);

            return $purchase;
        });
    }

    /**
     * @throws ValidationException
     */
    private function takeBack(User $actor, Purchase $purchase, PurchaseLine $line): void
    {
        $item = InventoryItem::query()->findOrFail($line->inventory_item_id);

        if ($line->quantity_milli > $this->ledger->quantity($purchase->branch_id, $item->id)) {
            throw ValidationException::withMessages(['purchase' => __('Part of :name from this purchase was already used. Correct it with a stock count.', [
                'name' => $item->name,
            ])]);
        }

        $this->ledger->move($purchase->branch_id, $item->id, -$line->quantity_milli, StockMovementReason::Cancellation, $actor->id, [
            'purchase_id' => $purchase->id,
        ]);

        $lastCost = PurchaseLine::query()
            ->join('purchases', 'purchases.id', '=', 'purchase_lines.purchase_id')
            ->where('purchase_lines.inventory_item_id', $item->id)
            ->where('purchase_lines.purchase_id', '!=', $purchase->id)
            ->whereNull('purchases.cancelled_at')
            ->latest('purchases.purchased_on')
            ->latest('purchases.created_at')
            ->value('purchase_lines.unit_cost');

        if ($lastCost !== null) {
            $item->forceFill(['unit_cost' => $lastCost])->save();
        }
    }
}
