<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Deletes a role that nobody holds, so staff never lose access silently.
 */
class DeleteRole
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Role $role): void
    {
        $holders = $role->users()->count();

        if ($holders > 0) {
            throw ValidationException::withMessages([
                'role' => trans_choice('This role is assigned to :count staff member. Reassign them first.|This role is assigned to :count staff members. Reassign them first.', $holders, ['count' => $holders]),
            ]);
        }

        DB::transaction(function () use ($actor, $role): void {
            $this->auditTrail->record('role.deleted', $role, $actor, 'Role deleted', [
                'name' => $role->name,
                'permissions' => $role->permissions->pluck('name')->all(),
            ]);

            $role->delete();
        });
    }
}
