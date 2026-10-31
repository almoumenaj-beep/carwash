<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Support\PermissionGrantGuard;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Replaces a role's permissions. The actor must hold every permission being added or removed.
 */
class SyncRolePermissions
{
    public function __construct(private PermissionGrantGuard $permissionGrantGuard, private AuditTrail $auditTrail) {}

    /**
     * @param  list<string>  $permissions
     */
    public function handle(User $actor, Role $role, array $permissions): Role
    {
        $current = $role->permissions->pluck('name');
        $added = collect($permissions)->diff($current)->values();
        $removed = $current->diff($permissions)->values();

        $this->permissionGrantGuard->authorize($actor, $added->merge($removed));

        if ($added->isEmpty() && $removed->isEmpty()) {
            return $role;
        }

        return DB::transaction(function () use ($actor, $role, $permissions, $added, $removed): Role {
            $role->syncPermissions($permissions);

            $this->auditTrail->record('role.permissions_synced', $role, $actor, 'Role permissions changed', [
                'added' => $added->all(),
                'removed' => $removed->all(),
            ]);

            return $role;
        });
    }
}
