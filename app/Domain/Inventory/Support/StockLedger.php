<?php

namespace App\Domain\Inventory\Support;

use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Models\InventoryStock;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * The only way stock changes: locks the branch's row for the material, applies the change and writes the
 * movement with the balance after it. Call inside a transaction.
 */
class StockLedger
{
    /**
     * @param  array{order_id?: string, purchase_id?: string, note?: ?string}  $context
     */
    public function move(string $branchId, string $itemId, int $changeMilli, StockMovementReason $reason, ?string $userId, array $context = []): StockMovement
    {
        $stock = $this->lockedStock($branchId, $itemId);
        $stock->quantity_milli += $changeMilli;
        $stock->save();

        $movement = new StockMovement;
        $movement->forceFill([
            'branch_id' => $branchId,
            'inventory_item_id' => $itemId,
            'reason' => $reason,
            'change_milli' => $changeMilli,
            'balance_milli' => $stock->quantity_milli,
            'order_id' => $context['order_id'] ?? null,
            'purchase_id' => $context['purchase_id'] ?? null,
            'note' => $context['note'] ?? null,
            'user_id' => $userId,
            'created_at' => now(),
        ])->save();

        return $movement;
    }

    /**
     * What the branch holds now, read under the same lock as a change.
     */
    public function quantity(string $branchId, string $itemId): int
    {
        return $this->lockedStock($branchId, $itemId)->quantity_milli;
    }

    /**
     * The branch's row for the material, created at zero the first time (insertOrIgnore, so two
     * requests creating it at once do not clash), then locked.
     */
    private function lockedStock(string $branchId, string $itemId): InventoryStock
    {
        $stock = InventoryStock::query()->where('branch_id', $branchId)->where('inventory_item_id', $itemId)->lockForUpdate()->first();

        if ($stock !== null) {
            return $stock;
        }

        DB::table('inventory_stock')->insertOrIgnore([
            'id' => (string) Str::uuid7(),
            'tenant_id' => app(TenantContext::class)->idOrFail(),
            'inventory_item_id' => $itemId,
            'branch_id' => $branchId,
            'quantity_milli' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return InventoryStock::query()->where('branch_id', $branchId)->where('inventory_item_id', $itemId)->lockForUpdate()->firstOrFail();
    }
}
