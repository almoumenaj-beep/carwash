<?php

namespace App\Domain\Expenses\Actions;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Pays an expense that was still owed, e.g. a supplier's invoice or a recurring rent.
 */
class PayExpense
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Expense $expense, ExpensePaymentMethod $method): Expense
    {
        return DB::transaction(function () use ($actor, $expense, $method): Expense {
            $expense = Expense::query()->whereKey($expense->getKey())->lockForUpdate()->firstOrFail();

            if ($expense->isPaid()) {
                throw ValidationException::withMessages(['expense' => __('This expense is already paid.')]);
            }

            $shift = $method === ExpensePaymentMethod::CashDrawer ? RecordExpense::openShift($actor, $expense->branch) : null;

            $expense->forceFill([
                'payment_method' => $method,
                'cash_shift_id' => $shift?->id,
                'paid_at' => now(),
                'paid_by' => $actor->id,
            ])->save();

            $this->auditTrail->record('expense.paid', $expense, $actor, 'Expense paid', [
                'amount' => $expense->amount,
                'payment_method' => $method->value,
            ]);

            return $expense;
        });
    }
}
