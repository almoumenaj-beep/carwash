<?php

namespace App\Domain\Platform\Policies;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Models\User;

class BranchPolicy
{
    /**
     * Every staff member may list branches; the list itself is limited to the branches they can access.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Branch $branch): bool
    {
        return $user->canAccessBranch($branch);
    }

    public function create(User $user): bool
    {
        return $user->can(Permission::SettingsManage->value);
    }

    public function update(User $user, Branch $branch): bool
    {
        return $user->can(Permission::SettingsManage->value) && $user->canAccessBranch($branch);
    }

    public function delete(User $user, Branch $branch): bool
    {
        return $user->can(Permission::SettingsManage->value) && $user->canAccessBranch($branch);
    }
}
