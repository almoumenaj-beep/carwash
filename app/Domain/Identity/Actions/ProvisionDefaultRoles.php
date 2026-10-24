<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Support\Facades\DB;

/**
 * Copies the default roles into a tenant. Safe to run again: existing default roles are left
 * untouched so the owner's customisations survive. Requires the permission catalog to be synced.
 */
class ProvisionDefaultRoles
{
    public function handle(Tenant $tenant): void
    {
        DB::transaction(function () use ($tenant): void {
            foreach (DefaultRole::cases() as $defaultRole) {
                $role = Role::query()->firstOrCreate(
                    ['tenant_id' => $tenant->id, 'key' => $defaultRole->value],
                    ['name' => $defaultRole->displayName(), 'guard_name' => config('auth.defaults.guard')],
                );

                if ($role->wasRecentlyCreated) {
                    $role->syncPermissions(array_map(fn (Permission $permission) => $permission->value, $defaultRole->permissions()));
                }
            }
        });
    }
}
