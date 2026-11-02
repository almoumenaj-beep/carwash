<?php

namespace App\Domain\Expenses\Policies;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Models\User;

/**
 * Expenses are seen with expenses.view, recorded with expenses.create, and paid or deleted with
 * expenses.approve — always within the branches the user works in.
 */
class ExpensePolicy
{
    public function create(User $user, Branch $branch): bool
    {
        return $user->can(Permission::ExpensesCreate->value) && $user->canAccessBranch($branch);
    }

    public function pay(User $user, Expense $expense): bool
    {
        return $user->can(Permission::ExpensesApprove->value) && $user->canAccessBranch($expense->branch);
    }

    public function delete(User $user, Expense $expense): bool
    {
        return $user->can(Permission::ExpensesApprove->value) && $user->canAccessBranch($expense->branch);
    }
}
