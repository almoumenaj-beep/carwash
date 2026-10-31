<?php

namespace App\Domain\Identity\Policies;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Device;
use App\Models\User;

class DevicePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can(Permission::UsersManage->value);
    }

    public function delete(User $user, Device $device): bool
    {
        return $user->can(Permission::UsersManage->value) && $device->tenant_id === $user->tenant_id;
    }
}
