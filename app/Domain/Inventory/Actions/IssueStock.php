<?php

namespace App\Domain\Inventory\Actions;

use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Models\InventoryItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Support\Quantity;
use App\Domain\Inventory\Support\StockLedger;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Takes materials out of a branch's stock by hand, for use that no service records (cleaning the site, a
 * towel handed out). It cannot take more than the branch holds. The cost was already an expense when the
 * material was bought, so no expense is recorded here.
 */
class IssueStock
{
    public function __construct(private StockLedger $ledger, private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Branch $branch, InventoryItem $item, int $quantityMilli, ?string $note): StockMovement
    {
        return DB::transaction(function () use ($actor, $branch, $item, $quantityMilli, $note): StockMovement {
            $available = $this->ledger->quantity($branch->id, $item->id);

            if ($quantityMilli > $available) {
                throw ValidationException::withMessages(['quantity' => __('Only :quantity :unit is in stock at this branch.', [
                    'quantity' => Quantity::fromMilli($available),
                    'unit' => $item->unit,
                ])]);
            }

            $movement = $this->ledger->move($branch->id, $item->id, -$quantityMilli, StockMovementReason::Issue, $actor->id, ['note' => $note]);
            $this->auditTrail->record('stock.issued', $item, $actor, 'Stock issued', [
                'branch_id' => $branch->id,
                'quantity_milli' => $quantityMilli,
            ]);

            return $movement;
        });
    }
}
