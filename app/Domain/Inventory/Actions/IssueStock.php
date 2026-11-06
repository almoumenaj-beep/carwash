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
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Issues materials from a branch's stock to a staff member, usually the day's supply: several materials at
 * once, all or none, and never more than the branch holds. The cost was already an expense when the materials
 * were bought, so no expense is recorded here.
 */
class IssueStock
{
    public function __construct(private StockLedger $ledger, private AuditTrail $auditTrail) {}

    /**
     * @param  list<array{inventory_item_id: string, quantity: int|float|string}>  $lines
     * @return Collection<int, StockMovement>
     *
     * @throws ValidationException
     */
    public function handle(User $actor, Branch $branch, User $receiver, array $lines, ?string $note): Collection
    {
        if (! $receiver->is_active || ! $receiver->canAccessBranch($branch)) {
            throw ValidationException::withMessages(['issued_to' => __('Choose an active staff member of this branch.')]);
        }

        $items = InventoryItem::query()->whereKey(array_column($lines, 'inventory_item_id'))->get()->keyBy('id');

        // One order for the row locks, so two issues at once cannot wait on each other.
        $ordered = collect($lines)->sortBy('inventory_item_id');

        return DB::transaction(function () use ($actor, $branch, $receiver, $note, $items, $ordered): Collection {
            $movements = $ordered->map(function (array $line, int $index) use ($actor, $branch, $receiver, $note, $items): StockMovement {
                $item = $items->get($line['inventory_item_id']);
                $quantity = Quantity::toMilli($line['quantity']);
                $available = $this->ledger->quantity($branch->id, $item->id);

                if ($quantity > $available) {
                    throw ValidationException::withMessages(["lines.{$index}.quantity" => __('Only :quantity :unit of :name is in stock at this branch.', [
                        'quantity' => Quantity::fromMilli($available),
                        'unit' => $item->unit,
                        'name' => $item->name,
                    ])]);
                }

                return $this->ledger->move($branch->id, $item->id, -$quantity, StockMovementReason::Issue, $actor->id, [
                    'note' => $note,
                    'issued_to' => $receiver->id,
                ]);
            })->values();

            $this->auditTrail->record('stock.issued', $branch, $actor, 'Stock issued', [
                'issued_to' => $receiver->id,
                'lines' => $movements->map(fn (StockMovement $movement) => [
                    'inventory_item_id' => $movement->inventory_item_id,
                    'quantity_milli' => -$movement->change_milli,
                ])->all(),
            ]);

            return $movements;
        });
    }
}
