<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Inventory\Actions\CountStock;
use App\Domain\Inventory\Actions\IssueStock;
use App\Domain\Inventory\Models\InventoryItem;
use App\Domain\Inventory\Models\InventoryStock;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Queries\DailyStockUsage;
use App\Domain\Inventory\Support\Quantity;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveInventoryItemRequest;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

/**
 * Materials with their stock at a branch (or across the user's branches), stock counts and the stock's
 * history. Seen with inventory.view; materials and counts change with inventory.adjust. Quantities are
 * decimal numbers of each material's unit.
 */
class InventoryController extends Controller
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * Every material with what the branch holds; `is_low` marks those at or below their minimum.
     */
    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::InventoryView->value);
        $request->validate(['branch_id' => ['sometimes', 'nullable', 'uuid']]);

        $branchIds = $this->branchIds($request);
        $stock = InventoryStock::query()
            ->whereIn('branch_id', $branchIds)
            ->groupBy('inventory_item_id')
            ->selectRaw('inventory_item_id, SUM(quantity_milli) AS quantity_milli')
            ->pluck('quantity_milli', 'inventory_item_id');

        $items = InventoryItem::query()->orderBy('name')->get();

        return response()->json(['data' => $items->map(fn (InventoryItem $item) => $this->present($item, (int) ($stock[$item->id] ?? 0)))]);
    }

    public function store(SaveInventoryItemRequest $request): JsonResponse
    {
        $item = InventoryItem::create($this->attributes($request));
        $this->auditTrail->record('inventory_item.created', $item, $request->user(), 'Material added', ['name' => $item->name]);

        return response()->json(['data' => $this->present($item, 0)], Response::HTTP_CREATED);
    }

    public function update(SaveInventoryItemRequest $request, InventoryItem $item): JsonResponse
    {
        $item->update($this->attributes($request));
        $this->auditTrail->record('inventory_item.updated', $item, $request->user(), 'Material updated', ['changed' => array_keys($item->getChanges())]);

        return response()->json(['data' => $this->present($item, (int) $item->stock()->whereIn('branch_id', $this->branchIds($request))->sum('quantity_milli'))]);
    }

    /**
     * Set a branch's stock of a material to what was counted; the response is the new quantity.
     */
    public function count(Request $request, CountStock $countStock): JsonResponse
    {
        Gate::authorize(Permission::InventoryAdjust->value);

        $tenantId = $request->user()->tenant_id;
        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'inventory_item_id' => ['required', 'uuid', Rule::exists('inventory_items', 'id')->where('tenant_id', $tenantId)],
            'quantity' => ['required', 'numeric', 'min:0', 'max:1000000', 'decimal:0,3'],
            'note' => ['nullable', 'string', 'max:255'],
        ]);

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);
        $item = InventoryItem::query()->findOrFail($request->input('inventory_item_id'));

        $countStock->handle($request->user(), $branch, $item, Quantity::toMilli($request->input('quantity')), $request->input('note'));

        return response()->json(['data' => $this->present($item, (int) $item->stock()->where('branch_id', $branch->id)->value('quantity_milli'))]);
    }

    /**
     * Issue materials from a branch's stock to a staff member; the response is the materials' new quantities.
     */
    public function issue(Request $request, IssueStock $issueStock): JsonResponse
    {
        Gate::authorize(Permission::InventoryAdjust->value);

        $tenantId = $request->user()->tenant_id;
        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'issued_to' => ['required', 'uuid', Rule::exists('users', 'id')->where('tenant_id', $tenantId)],
            'lines' => ['required', 'array', 'min:1', 'max:50'],
            'lines.*.inventory_item_id' => ['required', 'uuid', 'distinct', Rule::exists('inventory_items', 'id')->where('tenant_id', $tenantId)->where('is_active', true)],
            'lines.*.quantity' => ['required', 'numeric', 'gt:0', 'max:1000000', 'decimal:0,3'],
            'note' => ['nullable', 'string', 'max:255'],
        ]);

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);
        $receiver = User::query()->findOrFail($request->input('issued_to'));

        $movements = $issueStock->handle($request->user(), $branch, $receiver, $request->input('lines'), $request->input('note'));

        return response()->json(['data' => $movements->map(
            fn (StockMovement $movement) => $this->present($movement->loadMissing('item')->item, $movement->balance_milli),
        )], Response::HTTP_CREATED);
    }

    /**
     * What left a branch's stock on a day (`date`, default today in the car wash's time zone).
     */
    public function dailyUsage(Request $request, DailyStockUsage $dailyStockUsage): JsonResponse
    {
        Gate::authorize(Permission::InventoryView->value);

        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ]);

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        $timezone = $request->user()->tenant->timezone;
        $day = $request->filled('date')
            ? CarbonImmutable::createFromFormat('Y-m-d', $request->input('date'), $timezone)
            : CarbonImmutable::now($timezone);

        return response()->json(['data' => $dailyStockUsage->for($branch->id, $day)]);
    }

    /**
     * The latest stock changes at a branch, optionally for one material, newest first.
     */
    public function movements(Request $request): JsonResponse
    {
        Gate::authorize(Permission::InventoryView->value);
        $request->validate([
            'branch_id' => ['sometimes', 'nullable', 'uuid'],
            'inventory_item_id' => ['sometimes', 'nullable', 'uuid'],
        ]);

        $movements = StockMovement::query()
            ->whereIn('branch_id', $this->branchIds($request))
            ->when($request->filled('inventory_item_id'), fn ($query) => $query->where('inventory_item_id', $request->input('inventory_item_id')))
            ->with(['item', 'user', 'receiver'])
            ->latest('created_at')
            ->orderByDesc('id')
            ->limit(100)
            ->get();

        return response()->json(['data' => $movements->map(fn (StockMovement $movement) => [
            'id' => $movement->id,
            'branch_id' => $movement->branch_id,
            'item' => ['id' => $movement->item->id, 'name' => $movement->item->name, 'unit' => $movement->item->unit],
            'reason' => $movement->reason,
            'change' => Quantity::fromMilli($movement->change_milli),
            'balance' => Quantity::fromMilli($movement->balance_milli),
            'order_id' => $movement->order_id,
            'purchase_id' => $movement->purchase_id,
            'note' => $movement->note,
            'by' => $movement->user?->name,
            'received_by' => $movement->receiver?->name,
            'at' => $movement->created_at->toIso8601String(),
        ])]);
    }

    /**
     * @return array<string, mixed>
     */
    private function attributes(SaveInventoryItemRequest $request): array
    {
        $data = $request->safe()->except('min_stock');

        if ($request->has('min_stock')) {
            $data['min_stock_milli'] = Quantity::toMilli($request->input('min_stock'));
        }

        return $data;
    }

    /**
     * The requested branch, or every branch the user works in.
     *
     * @return list<string>
     */
    private function branchIds(Request $request): array
    {
        if (! $request->filled('branch_id')) {
            return $request->user()->accessibleBranches()->modelKeys();
        }

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        return [$branch->id];
    }

    /**
     * @return array<string, mixed>
     */
    private function present(InventoryItem $item, int $quantityMilli): array
    {
        return [
            'id' => $item->id,
            'name' => $item->name,
            'unit' => $item->unit,
            'unit_cost' => $item->unit_cost,
            'min_stock' => Quantity::fromMilli($item->min_stock_milli),
            'quantity' => Quantity::fromMilli($quantityMilli),
            'is_low' => $item->is_active && $quantityMilli <= $item->min_stock_milli,
            'is_active' => $item->is_active,
        ];
    }
}
