<?php

namespace App\Domain\Inventory\Actions;

use App\Domain\Expenses\Actions\RecordExpense;
use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Models\InventoryItem;
use App\Domain\Inventory\Models\Purchase;
use App\Domain\Inventory\Support\Quantity;
use App\Domain\Inventory\Support\StockLedger;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Records materials bought and received at a branch: stock goes up, each material's cost becomes the
 * price just paid, and the purchase is recorded as an expense — paid, or owed to the supplier when no
 * payment method is given.
 */
class RecordPurchase
{
    public function __construct(
        private StockLedger $ledger,
        private RecordExpense $recordExpense,
        private AuditTrail $auditTrail,
    ) {}

    /**
     * @param  array{branch_id: string, supplier_id?: ?string, expense_category_id: string, payment_method?: ?string, purchased_on?: ?string, note?: ?string, lines: list<array{inventory_item_id: string, quantity: int|float|string, unit_cost: int}>}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, array $data): Purchase
    {
        $purchasedOn = $data['purchased_on'] ?? CarbonImmutable::now($actor->tenant->timezone)->toDateString();
        $lines = array_map(function (array $line): array {
            $quantity = Quantity::toMilli($line['quantity']);

            return [
                'inventory_item_id' => $line['inventory_item_id'],
                'quantity_milli' => $quantity,
                'unit_cost' => (int) $line['unit_cost'],
                'line_total' => intdiv(2 * $quantity * (int) $line['unit_cost'] + 1000, 2000),
            ];
        }, $data['lines']);

        return DB::transaction(function () use ($actor, $data, $purchasedOn, $lines): Purchase {
            $total = array_sum(array_column($lines, 'line_total'));

            $purchase = new Purchase;
            $purchase->forceFill([
                'branch_id' => $data['branch_id'],
                'supplier_id' => $data['supplier_id'] ?? null,
                'purchased_on' => $purchasedOn,
                'total' => $total,
                'note' => $data['note'] ?? null,
                'created_by' => $actor->id,
            ])->save();
            $purchase->lines()->createMany($lines);

            foreach ($lines as $line) {
                $this->ledger->move($data['branch_id'], $line['inventory_item_id'], $line['quantity_milli'], StockMovementReason::Purchase, $actor->id, [
                    'purchase_id' => $purchase->id,
                ]);
                InventoryItem::query()->whereKey($line['inventory_item_id'])->update(['unit_cost' => $line['unit_cost']]);
            }

            $expense = $this->recordExpense->handle($actor, [
                'branch_id' => $data['branch_id'],
                'expense_category_id' => $data['expense_category_id'],
                'supplier_id' => $data['supplier_id'] ?? null,
                'amount' => max($total, 1),
                'spent_on' => $purchasedOn,
                'description' => $data['note'] ?? __('Materials purchase'),
                'payment_method' => $data['payment_method'] ?? null,
            ]);
            $purchase->forceFill(['expense_id' => $expense->id])->save();

            $this->auditTrail->record('purchase.recorded', $purchase, $actor, 'Purchase recorded', ['total' => $total, 'lines' => count($lines)]);

            return $purchase;
        });
    }
}
