<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Inventory\Actions\CancelPurchase;
use App\Domain\Inventory\Actions\RecordPurchase;
use App\Domain\Inventory\Models\Purchase;
use App\Domain\Inventory\Models\PurchaseLine;
use App\Domain\Inventory\Support\Quantity;
use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Requests\StorePurchaseRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Materials bought and received. Seen with inventory.view, recorded with inventory.purchase.
 */
class PurchaseController extends Controller
{
    private const RELATIONS = ['lines.item', 'supplier', 'expense', 'creator', 'canceller'];

    /**
     * The latest purchases at a branch (or at every branch the user works in), newest first.
     */
    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::InventoryView->value);
        $request->validate(['branch_id' => ['sometimes', 'nullable', 'uuid']]);

        if ($request->filled('branch_id')) {
            $branch = Branch::query()->findOrFail($request->input('branch_id'));
            Gate::authorize('view', $branch);
            $branchIds = [$branch->id];
        } else {
            $branchIds = $request->user()->accessibleBranches()->modelKeys();
        }

        $purchases = Purchase::query()->whereIn('branch_id', $branchIds)->with(self::RELATIONS)->latest('purchased_on')->latest()->limit(50)->get();

        return response()->json(['data' => $purchases->map($this->present(...))]);
    }

    public function store(StorePurchaseRequest $request, RecordPurchase $recordPurchase): JsonResponse
    {
        $purchase = $recordPurchase->handle($request->user(), $request->validated());

        return response()->json(['data' => $this->present($purchase->load(self::RELATIONS))], Response::HTTP_CREATED);
    }

    /**
     * Cancel a purchase recorded by mistake. One already paid takes its money back out of the books, so it also
     * needs expenses.approve.
     */
    public function cancel(Request $request, Purchase $purchase, CancelPurchase $cancelPurchase): JsonResponse
    {
        Gate::authorize(Permission::InventoryPurchase->value);
        Gate::authorize('view', Branch::query()->findOrFail($purchase->branch_id));

        if ($purchase->expense?->isPaid()) {
            Gate::authorize(Permission::ExpensesApprove->value);
        }

        return response()->json(['data' => $this->present($cancelPurchase->handle($request->user(), $purchase)->load(self::RELATIONS))]);
    }

    /**
     * @return array<string, mixed>
     */
    private function present(Purchase $purchase): array
    {
        return [
            'id' => $purchase->id,
            'branch_id' => $purchase->branch_id,
            'supplier' => $purchase->supplier === null ? null : ['id' => $purchase->supplier->id, 'name' => $purchase->supplier->name],
            'purchased_on' => $purchase->purchased_on->toDateString(),
            'total' => $purchase->total,
            'note' => $purchase->note,
            'is_paid' => $purchase->expense?->isPaid() ?? false,
            'is_cancelled' => $purchase->isCancelled(),
            'cancelled_by' => $purchase->canceller?->name,
            'lines' => $purchase->lines->map(fn (PurchaseLine $line) => [
                'item' => ['id' => $line->item->id, 'name' => $line->item->name, 'unit' => $line->item->unit],
                'quantity' => Quantity::fromMilli($line->quantity_milli),
                'unit_cost' => $line->unit_cost,
                'line_total' => $line->line_total,
            ])->values(),
            'created_by' => ['id' => $purchase->creator->id, 'name' => $purchase->creator->name],
        ];
    }
}
