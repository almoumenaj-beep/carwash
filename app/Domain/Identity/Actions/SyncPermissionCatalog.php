<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Enums\Permission;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission as PermissionModel;
use Spatie\Permission\PermissionRegistrar;

/**
 * Makes the permissions table match the Permission enum: adds new permissions and removes
 * ones dropped from the catalog (which also detaches them from every role).
 */
class SyncPermissionCatalog
{
    public function __construct(private PermissionRegistrar $permissionRegistrar) {}

    public function handle(): void
    {
        $guardName = config('auth.defaults.guard');

        DB::transaction(function () use ($guardName): void {
            foreach (Permission::cases() as $permission) {
                PermissionModel::findOrCreate($permission->value, $guardName);
            }

            PermissionModel::query()
                ->where('guard_name', $guardName)
                ->whereNotIn('name', Permission::values())
                ->get()
                ->each->delete();
        });

        $this->permissionRegistrar->forgetCachedPermissions();
    }
}
