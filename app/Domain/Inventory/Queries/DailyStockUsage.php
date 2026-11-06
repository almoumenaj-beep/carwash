<?php

namespace App\Domain\Inventory\Queries;

use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Support\Quantity;
use Carbon\CarbonImmutable;

/**
 * What left a branch's stock on one day, midnight to midnight in the car wash's time zone: per material, what
 * was issued to staff and anything washes used, valued at today's cost; and each issue with who received it,
 * including cancelled ones, which no longer count. Differences found by stock counts are not usage, so they are
 * left out.
 */
class DailyStockUsage
{
    /**
     * @return array<string, mixed>
     */
    public function for(string $branchId, CarbonImmutable $day): array
    {
        $movements = StockMovement::query()
            ->where('branch_id', $branchId)
            ->whereIn('reason', [StockMovementReason::Consumption, StockMovementReason::Issue])
            ->where('created_at', '>=', $day->startOfDay()->utc())
            ->where('created_at', '<', $day->startOfDay()->addDay()->utc())
            ->with(['item', 'user', 'receiver', 'reversal.user'])
            ->latest('created_at')
            ->orderByDesc('id')
            ->get();

        $items = $movements->whereNull('reversal')->groupBy('inventory_item_id')->map(function ($group): array {
            $item = $group->first()->item;
            $used = fn (StockMovementReason $reason): int => -(int) $group->where('reason', $reason)->sum('change_milli');
            $washes = $used(StockMovementReason::Consumption);
            $issued = $used(StockMovementReason::Issue);

            return [
                'item' => ['id' => $item->id, 'name' => $item->name, 'unit' => $item->unit],
                'washes' => Quantity::fromMilli($washes),
                'issued' => Quantity::fromMilli($issued),
                'total' => Quantity::fromMilli($washes + $issued),
                'cost' => intdiv(2 * ($washes + $issued) * $item->unit_cost + 1000, 2000),
            ];
        })->sortBy(fn (array $row) => $row['item']['name'])->values();

        return [
            'date' => $day->toDateString(),
            'total_cost' => $items->sum('cost'),
            'items' => $items->all(),
            'issues' => $movements->where('reason', StockMovementReason::Issue)->map(fn (StockMovement $movement) => [
                'id' => $movement->id,
                'item' => ['id' => $movement->item->id, 'name' => $movement->item->name, 'unit' => $movement->item->unit],
                'quantity' => Quantity::fromMilli(-$movement->change_milli),
                'is_cancelled' => $movement->reversal !== null,
                'cancelled_by' => $movement->reversal?->user?->name,
                'note' => $movement->note,
                'by' => $movement->user?->name,
                'received_by' => $movement->receiver?->name,
                'at' => $movement->created_at->toIso8601String(),
            ])->values()->all(),
        ];
    }
}
