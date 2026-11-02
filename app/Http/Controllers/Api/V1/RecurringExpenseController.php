<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Expenses\Models\RecurringExpense;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Audit\AuditTrail;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveRecurringExpenseRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Recurring expenses (rent, subscriptions) of the branches the user works in. On each due date an owed
 * expense is recorded by `expenses:generate-recurring`. Seen with expenses.view, changed with expenses.approve.
 */
class RecurringExpenseController extends Controller
{
    private const RELATIONS = ['category', 'supplier'];

    public function __construct(private AuditTrail $auditTrail) {}

    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::ExpensesView->value);

        $schedules = RecurringExpense::query()
            ->whereIn('branch_id', $request->user()->accessibleBranches()->modelKeys())
            ->with(self::RELATIONS)
            ->orderBy('next_due_on')
            ->get();

        return response()->json(['data' => $schedules->map($this->present(...))]);
    }

    public function store(SaveRecurringExpenseRequest $request): JsonResponse
    {
        $schedule = new RecurringExpense($request->validated());
        $schedule->forceFill(['created_by' => $request->user()->id])->save();
        $this->auditTrail->record('recurring_expense.created', $schedule, $request->user(), 'Recurring expense added', ['amount' => $schedule->amount]);

        return response()->json(['data' => $this->present($schedule->load(self::RELATIONS))], Response::HTTP_CREATED);
    }

    public function update(SaveRecurringExpenseRequest $request, RecurringExpense $recurringExpense): JsonResponse
    {
        $recurringExpense->update($request->validated());
        $this->auditTrail->record('recurring_expense.updated', $recurringExpense, $request->user(), 'Recurring expense updated', ['changed' => array_keys($recurringExpense->getChanges())]);

        return response()->json(['data' => $this->present($recurringExpense->load(self::RELATIONS))]);
    }

    /**
     * Stop a schedule for good; expenses it already recorded stay.
     */
    public function destroy(Request $request, RecurringExpense $recurringExpense): Response
    {
        Gate::authorize(Permission::ExpensesApprove->value);
        Gate::authorize('view', $recurringExpense->branch);

        $this->auditTrail->record('recurring_expense.deleted', $recurringExpense, $request->user(), 'Recurring expense deleted', ['amount' => $recurringExpense->amount]);
        $recurringExpense->delete();

        return response()->noContent();
    }

    /**
     * @return array<string, mixed>
     */
    private function present(RecurringExpense $schedule): array
    {
        return [
            'id' => $schedule->id,
            'branch_id' => $schedule->branch_id,
            'category' => ['id' => $schedule->category->id, 'name' => $schedule->category->name],
            'supplier' => $schedule->supplier === null ? null : ['id' => $schedule->supplier->id, 'name' => $schedule->supplier->name],
            'amount' => $schedule->amount,
            'description' => $schedule->description,
            'frequency' => $schedule->frequency,
            'next_due_on' => $schedule->next_due_on->toDateString(),
            'is_active' => $schedule->is_active,
        ];
    }
}
