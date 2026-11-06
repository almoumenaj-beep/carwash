<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Audit\AuditTrail;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveExpenseCategoryRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

/**
 * Expense categories. Seen with expenses.view, changed with expenses.approve; a category in use is
 * deactivated rather than deleted.
 */
class ExpenseCategoryController extends Controller
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * Also read by staff recording purchases, which are filed under a category.
     */
    public function index(): JsonResponse
    {
        abort_unless(Gate::any([Permission::ExpensesView->value, Permission::InventoryPurchase->value]), Response::HTTP_FORBIDDEN);

        return response()->json(['data' => ExpenseCategory::query()->orderBy('sort_order')->orderBy('name')->get()->map($this->present(...))]);
    }

    public function store(SaveExpenseCategoryRequest $request): JsonResponse
    {
        $category = ExpenseCategory::create([
            'sort_order' => (ExpenseCategory::query()->max('sort_order') ?? -1) + 1,
            ...$request->validated(),
        ]);
        $this->auditTrail->record('expense_category.created', $category, $request->user(), 'Expense category added', ['name' => $category->name]);

        return response()->json(['data' => $this->present($category)], Response::HTTP_CREATED);
    }

    public function update(SaveExpenseCategoryRequest $request, ExpenseCategory $expenseCategory): JsonResponse
    {
        $expenseCategory->update($request->validated());
        $this->auditTrail->record('expense_category.updated', $expenseCategory, $request->user(), 'Expense category updated', ['changed' => array_keys($expenseCategory->getChanges())]);

        return response()->json(['data' => $this->present($expenseCategory)]);
    }

    /**
     * @throws ValidationException
     */
    public function destroy(Request $request, ExpenseCategory $expenseCategory): Response
    {
        Gate::authorize(Permission::ExpensesApprove->value);

        if ($expenseCategory->isInUse()) {
            throw ValidationException::withMessages(['expense_category' => __('This category has expenses. Deactivate it instead of deleting it.')]);
        }

        $this->auditTrail->record('expense_category.deleted', $expenseCategory, $request->user(), 'Expense category deleted', ['name' => $expenseCategory->name]);
        $expenseCategory->delete();

        return response()->noContent();
    }

    /**
     * @return array<string, mixed>
     */
    private function present(ExpenseCategory $category): array
    {
        return [
            'id' => $category->id,
            'name' => $category->name,
            'sort_order' => $category->sort_order,
            'is_active' => $category->is_active,
        ];
    }
}
