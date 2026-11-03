<?php

namespace App\Domain\Staff\Actions;

use App\Domain\Expenses\Actions\RecordExpense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Staff\Models\SalaryAdvance;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Advances money to a staff member: recorded as an expense when paid out (cash from the drawer lowers
 * the payer's shift), and deducted from their next payroll.
 */
class GiveSalaryAdvance
{
    public function __construct(private RecordExpense $recordExpense, private AuditTrail $auditTrail) {}

    /**
     * @param  array{user_id: string, branch_id: string, amount: int, expense_category_id: string, payment_method: string, note?: ?string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, User $staff, array $data): SalaryAdvance
    {
        return DB::transaction(function () use ($actor, $staff, $data): SalaryAdvance {
            $expense = $this->recordExpense->handle($actor, [
                'branch_id' => $data['branch_id'],
                'expense_category_id' => $data['expense_category_id'],
                'amount' => $data['amount'],
                'description' => __('Salary advance: :name', ['name' => $staff->name]),
                'payment_method' => $data['payment_method'],
            ]);

            $advance = new SalaryAdvance;
            $advance->forceFill([
                'user_id' => $staff->id,
                'branch_id' => $data['branch_id'],
                'amount' => $data['amount'],
                'given_on' => CarbonImmutable::now($actor->tenant->timezone)->toDateString(),
                'note' => $data['note'] ?? null,
                'expense_id' => $expense->id,
                'created_by' => $actor->id,
            ])->save();

            $this->auditTrail->record('salary_advance.given', $advance, $actor, 'Salary advance given', [
                'user_id' => $staff->id,
                'amount' => $advance->amount,
            ]);

            return $advance;
        });
    }
}
