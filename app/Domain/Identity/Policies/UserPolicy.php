<?php

namespace App\Domain\Identity\Policies;

use App\Domain\Identity\Enums\Permission;
use App\Models\User;

/**
 * Staff management. Users with access to only some branches manage only staff limited to
 * branches they share; nobody but an owner manages an owner.
 */
class UserPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can(Permission::UsersManage->value);
    }

    public function view(User $user, User $staff): bool
    {
        return $this->manages($user, $staff);
    }

    public function create(User $user): bool
    {
        return $user->can(Permission::UsersManage->value);
    }

    public function update(User $user, User $staff): bool
    {
        return $this->manages($user, $staff)
            && (! $staff->isOwner() || $user->isOwner());
    }

    public function delete(User $user, User $staff): bool
    {
        return $user->isNot($staff) && $this->update($user, $staff);
    }

    private function manages(User $user, User $staff): bool
    {
        if (! $user->can(Permission::UsersManage->value) || $staff->tenant_id !== $user->tenant_id) {
            return false;
        }

        if ($user->hasAllBranchAccess()) {
            return true;
        }

        return ! $staff->hasAllBranchAccess()
            && $staff->branches()->whereIn('branches.id', $user->branches()->select('branches.id'))->exists();
    }
}
