<?php

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\PermissionRegistrar;

return new class extends Migration
{
    /**
     * Adds the equipment permissions to the catalog and gives them to the default roles of existing car
     * washes that start with them (branch managers manage equipment, accountants see it).
     */
    public function up(): void
    {
        $tables = config('permission.table_names');
        $equipment = [Permission::EquipmentView, Permission::EquipmentManage];

        foreach ($equipment as $permission) {
            DB::table($tables['permissions'])->insertOrIgnore([
                'name' => $permission->value,
                'guard_name' => Role::GUARD_NAME,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
        $permissionIds = DB::table($tables['permissions'])->where('guard_name', Role::GUARD_NAME)->pluck('id', 'name');

        foreach (DefaultRole::cases() as $defaultRole) {
            $granted = array_filter($equipment, fn (Permission $permission) => in_array($permission, $defaultRole->permissions(), true));

            foreach (DB::table($tables['roles'])->where('key', $defaultRole->value)->pluck('id') as $roleId) {
                foreach ($granted as $permission) {
                    DB::table($tables['role_has_permissions'])->insertOrIgnore([
                        'permission_id' => $permissionIds[$permission->value],
                        'role_id' => $roleId,
                    ]);
                }
            }
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    public function down(): void
    {
        DB::table(config('permission.table_names.permissions'))
            ->whereIn('name', [Permission::EquipmentView->value, Permission::EquipmentManage->value])
            ->delete();
        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
