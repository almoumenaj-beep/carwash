<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Support\PermissionGrantGuard;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Creates a custom role in the actor's tenant.
 */
class CreateRole
{
    public function __construct(private PermissionGrantGuard $permissionGrantGuard, private AuditTrail $auditTrail) {}

    /**
     * @param  list<string>  $permissions
     */
    public function handle(User $actor, string $name, array $permissions): Role
    {
        $this->permissionGrantGuard->authorize($actor, $permissions);

        return DB::transaction(function () use ($actor, $name, $permissions): Role {
            $role = Role::create([
                'name' => $name,
                'tenant_id' => $actor->tenant_id,
                'guard_name' => Role::GUARD_NAME,
            ]);

            $role->syncPermissions($permissions);

            $this->auditTrail->record('role.created', $role, $actor, 'Role created', [
                'name' => $name,
                'permissions' => $permissions,
            ]);

            return $role;
        });
    }
}
