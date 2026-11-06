<?php

namespace App\Domain\Inventory\Actions;

use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Support\StockLedger;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Cancels materials issued by mistake: a movement puts the quantity back in the branch's stock, and the issue
 * stays on record marked as cancelled. An issue can only be cancelled once.
 */
class CancelStockIssue
{
    public function __construct(private StockLedger $ledger, private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, StockMovement $issue): StockMovement
    {
        return DB::transaction(function () use ($actor, $issue): StockMovement {
            $issue = StockMovement::query()->lockForUpdate()->findOrFail($issue->id);

            if ($issue->reason !== StockMovementReason::Issue) {
                throw ValidationException::withMessages(['movement' => __('Only materials issued to staff can be cancelled.')]);
            }
            if ($issue->reversal()->exists()) {
                throw ValidationException::withMessages(['movement' => __('This issue was already cancelled.')]);
            }

            $reversal = $this->ledger->move($issue->branch_id, $issue->inventory_item_id, -$issue->change_milli, StockMovementReason::Reversal, $actor->id, [
                'reverses_movement_id' => $issue->id,
            ]);

            $this->auditTrail->record('stock.issue_cancelled', $issue, $actor, 'Stock issue cancelled', [
                'inventory_item_id' => $issue->inventory_item_id,
                'quantity_milli' => -$issue->change_milli,
            ]);

            return $reversal;
        });
    }
}
