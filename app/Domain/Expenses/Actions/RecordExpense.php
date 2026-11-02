<?php

namespace App\Domain\Expenses\Actions;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Domain\Sales\Models\CashShift;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Validation\ValidationException;

/**
 * Records money spent by a branch: paid now (cash from the drawer goes on the payer's open shift there,
 * and is dated today), or left owed when no payment method is given.
 */
class RecordExpense
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{branch_id: string, expense_category_id: string, supplier_id?: ?string, amount: int, spent_on?: ?string, description?: ?string, payment_method?: ?string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, array $data): Expense
    {
        $branch = Branch::query()->findOrFail($data['branch_id']);
        $method = isset($data['payment_method']) ? ExpensePaymentMethod::from($data['payment_method']) : null;
        $today = CarbonImmutable::now($actor->tenant->timezone)->toDateString();
        $shift = $method === ExpensePaymentMethod::CashDrawer ? self::openShift($actor, $branch) : null;

        $expense = new Expense;
        $expense->forceFill([
            'branch_id' => $branch->id,
            'expense_category_id' => $data['expense_category_id'],
            'supplier_id' => $data['supplier_id'] ?? null,
            'amount' => $data['amount'],
            'spent_on' => $shift !== null ? $today : ($data['spent_on'] ?? $today),
            'description' => $data['description'] ?? null,
            'payment_method' => $method,
            'cash_shift_id' => $shift?->id,
            'paid_at' => $method === null ? null : now(),
            'paid_by' => $method === null ? null : $actor->id,
            'created_by' => $actor->id,
        ])->save();

        $this->auditTrail->record('expense.recorded', $expense, $actor, 'Expense recorded', [
            'amount' => $expense->amount,
            'payment_method' => $method?->value,
        ]);

        return $expense;
    }

    /**
     * The payer's open shift at the branch, whose drawer the cash comes out of.
     *
     * @throws ValidationException
     */
    public static function openShift(User $actor, Branch $branch): CashShift
    {
        return CashShift::openFor($actor, $branch)
            ?? throw ValidationException::withMessages([
                'payment_method' => __('Open your shift at this branch to pay from its drawer.'),
            ]);
    }
}
