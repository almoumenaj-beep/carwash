<?php

namespace App\Domain\Expenses\Actions;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\RecurringExpense;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * Records the recurring expenses that have fallen due at a tenant as owed expenses, one per due date
 * (so missed days catch up), and moves each schedule on to its next due date.
 */
class GenerateDueRecurringExpenses
{
    public function __construct(private TenantContext $tenantContext) {}

    /**
     * @return int How many expenses were recorded.
     */
    public function handle(Tenant $tenant): int
    {
        return $this->tenantContext->run($tenant, function () use ($tenant): int {
            $today = CarbonImmutable::now($tenant->timezone)->startOfDay();
            $created = 0;

            $due = RecurringExpense::query()->where('is_active', true)->where('next_due_on', '<=', $today->toDateString())->get();

            foreach ($due as $schedule) {
                DB::transaction(function () use ($schedule, $today, &$created): void {
                    $dueOn = $schedule->next_due_on;

                    // Calendar dates, compared as Y-m-d: the due date has no time zone, today is the tenant's.
                    while ($dueOn->toDateString() <= $today->toDateString()) {
                        $expense = new Expense;
                        $expense->forceFill([
                            'branch_id' => $schedule->branch_id,
                            'expense_category_id' => $schedule->expense_category_id,
                            'supplier_id' => $schedule->supplier_id,
                            'recurring_expense_id' => $schedule->id,
                            'amount' => $schedule->amount,
                            'spent_on' => $dueOn->toDateString(),
                            'description' => $schedule->description,
                            'created_by' => $schedule->created_by,
                        ])->save();

                        $created++;
                        $dueOn = $schedule->frequency->after($dueOn);
                    }

                    $schedule->forceFill(['next_due_on' => $dueOn->toDateString()])->save();
                });
            }

            return $created;
        });
    }
}
