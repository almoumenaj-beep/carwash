<?php

namespace App\Domain\Identity\Policies;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Models\User;

class RolePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can(Permission::RolesManage->value);
    }

    public function view(User $user, Role $role): bool
    {
        return $this->managesRolesOf($user, $role);
    }

    public function create(User $user): bool
    {
        return $user->can(Permission::RolesManage->value);
    }

    /**
     * The owner role always holds every permission, so nobody may edit it.
     */
    public function update(User $user, Role $role): bool
    {
        return $this->managesRolesOf($user, $role) && ! $role->isOwnerRole();
    }

    public function delete(User $user, Role $role): bool
    {
        return $this->managesRolesOf($user, $role) && ! $role->isOwnerRole();
    }

    private function managesRolesOf(User $user, Role $role): bool
    {
        return $user->can(Permission::RolesManage->value)
            && $role->tenant_id !== null
            && $role->tenant_id === $user->tenant_id;
    }
}
