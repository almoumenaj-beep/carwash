<?php

namespace App\Domain\Inventory\Queries;

use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Support\Quantity;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * What left a branch's stock on one day, midnight to midnight in the car wash's time zone: per material, what
 * the washes used and what was issued by hand, valued at today's cost; and each hand issue with who made it.
 * Differences found by stock counts are not usage, so they are left out.
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
            ->with(['item', 'user'])
            ->latest('created_at')
            ->orderByDesc('id')
            ->get();

        $items = $movements->groupBy('inventory_item_id')->map(function ($group): array {
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
                'item' => ['id' => $movement->item->id, 'name' => $movement->item->name, 'unit' => $movement->item->unit],
                'quantity' => Quantity::fromMilli(-$movement->change_milli),
                'note' => $movement->note,
                'by' => $movement->user?->name,
                'at' => $movement->created_at->toIso8601String(),
            ])->values()->all(),
            'materials_set_up' => DB::table('service_materials')
                ->join('services', 'services.id', '=', 'service_materials.service_id')
                ->where('services.tenant_id', $this->tenantId($branchId))
                ->exists(),
        ];
    }

    private function tenantId(string $branchId): string
    {
        return (string) DB::table('branches')->where('id', $branchId)->value('tenant_id');
    }
}
