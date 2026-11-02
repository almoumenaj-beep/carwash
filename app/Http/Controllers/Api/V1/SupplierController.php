<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Expenses\Models\Supplier;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Audit\AuditTrail;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveSupplierRequest;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Suppliers with what is still owed to them (their unpaid expenses). Seen with expenses.view, changed
 * with expenses.approve; deactivated rather than deleted, to keep their history.
 */
class SupplierController extends Controller
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function index(): JsonResponse
    {
        Gate::authorize(Permission::ExpensesView->value);

        $suppliers = Supplier::query()
            ->withSum(['expenses as owed' => fn (Builder $query) => $query->whereNull('paid_at')], 'amount')
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $suppliers->map($this->present(...))]);
    }

    public function store(SaveSupplierRequest $request): JsonResponse
    {
        $supplier = Supplier::create($request->validated());
        $this->auditTrail->record('supplier.created', $supplier, $request->user(), 'Supplier added', ['name' => $supplier->name]);

        return response()->json(['data' => $this->present($supplier)], Response::HTTP_CREATED);
    }

    public function update(SaveSupplierRequest $request, Supplier $supplier): JsonResponse
    {
        $supplier->update($request->validated());
        $this->auditTrail->record('supplier.updated', $supplier, $request->user(), 'Supplier updated', ['changed' => array_keys($supplier->getChanges())]);

        return response()->json(['data' => $this->present($supplier)]);
    }

    /**
     * @return array<string, mixed>
     */
    private function present(Supplier $supplier): array
    {
        return [
            'id' => $supplier->id,
            'name' => $supplier->name,
            'phone' => $supplier->phone,
            'notes' => $supplier->notes,
            'is_active' => $supplier->is_active,
            'owed' => (int) ($supplier->owed ?? $supplier->expenses()->whereNull('paid_at')->sum('amount')),
        ];
    }
}
