<?php

namespace App\Domain\Staff\Actions;

use App\Domain\Expenses\Actions\RecordExpense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Staff\Models\PayrollRun;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Pays a month: recalculates it one last time, records what is paid out as an expense, and fixes the month.
 */
class PayPayroll
{
    public function __construct(
        private CalculatePayroll $calculatePayroll,
        private RecordExpense $recordExpense,
        private AuditTrail $auditTrail,
    ) {}

    /**
     * @param  array{branch_id: string, expense_category_id: string, payment_method: string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, PayrollRun $run, array $data): PayrollRun
    {
        return DB::transaction(function () use ($actor, $run, $data): PayrollRun {
            $run = PayrollRun::query()->whereKey($run->getKey())->lockForUpdate()->firstOrFail();

            if ($run->isPaid()) {
                throw ValidationException::withMessages(['payroll' => __('This month has been paid and can no longer change.')]);
            }

            $this->calculatePayroll->fill($run, $actor->tenant);
            $payout = (int) $run->lines()->where('net', '>', 0)->sum('net');

            $expense = $payout === 0 ? null : $this->recordExpense->handle($actor, [
                'branch_id' => $data['branch_id'],
                'expense_category_id' => $data['expense_category_id'],
                'amount' => $payout,
                'description' => __('Payroll :month/:year', ['month' => $run->month, 'year' => $run->year]),
                'payment_method' => $data['payment_method'],
            ]);

            $run->forceFill([
                'status' => 'paid',
                'expense_id' => $expense?->id,
                'paid_at' => now(),
                'paid_by' => $actor->id,
            ])->save();

            $this->auditTrail->record('payroll.paid', $run, $actor, 'Payroll paid', ['total_net' => $run->total_net, 'paid_out' => $payout]);

            return $run;
        });
    }
}
