<?php

namespace App\Domain\Staff\Actions;

use App\Domain\Expenses\Actions\RecordExpense;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Pays a daily-paid staff member for a day: records the money out as an expense under the wages category,
 * linked to the employee. The amount is whatever was agreed that day, so it is not tied to the profile's
 * salary amount.
 */
class RecordDailyWage
{
    public function __construct(
        private RecordExpense $recordExpense,
        private AuditTrail $auditTrail,
    ) {}

    /**
     * @param  array{branch_id: string, amount: int, spent_on?: ?string, payment_method?: ?string, expense_category_id?: ?string, description?: ?string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, User $employee, array $data): Expense
    {
        return DB::transaction(function () use ($actor, $employee, $data): Expense {
            $categoryId = $data['expense_category_id'] ?? self::wagesCategory()?->id
                ?? throw ValidationException::withMessages(['expense_category_id' => __('Add an expense category first.')]);

            $expense = $this->recordExpense->handle($actor, [
                ...$data,
                'expense_category_id' => $categoryId,
                'employee_id' => $employee->id,
            ]);

            $this->auditTrail->record('employee.daily_wage_paid', $expense, $actor, 'Daily wage paid', [
                'employee_id' => $employee->id,
                'amount' => $expense->amount,
            ]);

            return $expense;
        });
    }

    /**
     * The category daily wages are recorded under: "Wages" (or the Arabic default) when it exists, else the first active one.
     */
    public static function wagesCategory(): ?ExpenseCategory
    {
        $active = ExpenseCategory::query()->where('is_active', true)->get();

        return $active
            ->first(fn (ExpenseCategory $category) => str_contains($category->name, 'رواتب') || str_contains(strtolower($category->name), 'wage'))
            ?? $active->first();
    }
}
