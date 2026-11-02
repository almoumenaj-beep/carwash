<?php

namespace App\Domain\Expenses\Actions;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Deletes an expense recorded by mistake. Cash taken from a drawer whose shift is closed stays, since
 * the shift's count already relies on it.
 */
class DeleteExpense
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Expense $expense): void
    {
        if ($expense->cash_shift_id !== null && ! $expense->cashShift->isOpen()) {
            throw ValidationException::withMessages(['expense' => __('This expense was counted in a closed shift and cannot be deleted.')]);
        }

        DB::transaction(function () use ($actor, $expense): void {
            $this->auditTrail->record('expense.deleted', $expense, $actor, 'Expense deleted', [
                'amount' => $expense->amount,
                'spent_on' => $expense->spent_on->toDateString(),
            ]);

            $expense->delete();
        });
    }
}
