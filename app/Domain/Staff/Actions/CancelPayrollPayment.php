<?php

namespace App\Domain\Staff\Actions;

use App\Domain\Expenses\Actions\DeleteExpense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Staff\Models\PayrollRun;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Cancels a month's payment recorded by mistake: its expense is removed and the month is a draft again, to be
 * reviewed and paid again.
 */
class CancelPayrollPayment
{
    public function __construct(private DeleteExpense $deleteExpense, private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, PayrollRun $run): PayrollRun
    {
        return DB::transaction(function () use ($actor, $run): PayrollRun {
            $run = PayrollRun::query()->with('expense.cashShift')->lockForUpdate()->findOrFail($run->id);

            if (! $run->isPaid()) {
                throw ValidationException::withMessages(['payroll' => __('This month has not been paid.')]);
            }

            $expense = $run->expense;
            if ($expense !== null) {
                $this->deleteExpense->remove($actor, $expense);
            }

            $run->forceFill(['status' => 'draft', 'expense_id' => null, 'paid_at' => null, 'paid_by' => null])->save();

            $this->auditTrail->record('payroll.payment_cancelled', $run, $actor, 'Payroll payment cancelled', [
                'total_net' => $run->total_net,
                'amount' => $expense?->amount,
            ]);

            return $run;
        });
    }
}
