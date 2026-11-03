<?php

namespace App\Domain\Inventory\Actions;

use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Models\InventoryItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Support\StockLedger;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Sets a branch's stock of a material to what was actually counted; the difference is recorded as a
 * movement (nothing is recorded when the count matches).
 */
class CountStock
{
    public function __construct(private StockLedger $ledger, private AuditTrail $auditTrail) {}

    public function handle(User $actor, Branch $branch, InventoryItem $item, int $countedMilli, ?string $note): ?StockMovement
    {
        return DB::transaction(function () use ($actor, $branch, $item, $countedMilli, $note): ?StockMovement {
            $difference = $countedMilli - $this->ledger->quantity($branch->id, $item->id);

            if ($difference === 0) {
                return null;
            }

            $movement = $this->ledger->move($branch->id, $item->id, $difference, StockMovementReason::Count, $actor->id, ['note' => $note]);
            $this->auditTrail->record('stock.counted', $item, $actor, 'Stock counted', [
                'branch_id' => $branch->id,
                'counted_milli' => $countedMilli,
                'difference_milli' => $difference,
            ]);

            return $movement;
        });
    }
}
