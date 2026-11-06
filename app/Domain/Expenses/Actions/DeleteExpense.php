<?php

namespace App\Domain\Expenses\Actions;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Deletes an expense recorded by mistake. Cash taken from a drawer whose shift is closed stays, since
 * the shift's count already relies on it. An expense that is the money side of a purchase, payroll or
 * maintenance is managed from there, or the two would disagree.
 */
class DeleteExpense
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Expense $expense): void
    {
        if ($expense->source() !== null) {
            throw ValidationException::withMessages(['expense' => __(match ($expense->source()) {
                'purchase' => 'This expense came from an inventory purchase. Cancel the purchase from the inventory.',
                'payroll' => 'This expense came from payroll. Cancel the payment from the payroll.',
                default => 'This expense came from equipment maintenance. Cancel it from the equipment.',
            })]);
        }

        $this->remove($actor, $expense);
    }

    /**
     * Removes the expense, for whatever owns it to call when it goes.
     *
     * @throws ValidationException
     */
    public function remove(User $actor, Expense $expense): void
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
