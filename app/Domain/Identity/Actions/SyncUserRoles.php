<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Support\PermissionGrantGuard;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Replaces a staff member's roles in the current tenant.
 *
 * Rules: the actor must hold every permission of the roles being added or removed, only an
 * owner grants or revokes the owner role, and the tenant always keeps at least one owner.
 */
class SyncUserRoles
{
    public function __construct(private PermissionGrantGuard $permissionGrantGuard, private AuditTrail $auditTrail) {}

    /**
     * @param  list<int>  $roleIds
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function handle(User $actor, User $staff, array $roleIds): void
    {
        /** @var Collection<int, Role> $newRoles */
        $newRoles = Role::query()->ofTenant($staff->tenant_id)->whereKey($roleIds)->with('permissions')->get();
        /** @var Collection<int, Role> $currentRoles */
        $currentRoles = $staff->roles()->with('permissions')->get();

        $addedRoles = $newRoles->whereNotIn('id', $currentRoles->modelKeys());
        $removedRoles = $currentRoles->whereNotIn('id', $newRoles->modelKeys());
        $changedRoles = $addedRoles->concat($removedRoles);

        if ($changedRoles->isEmpty()) {
            return;
        }

        if ($changedRoles->contains(fn (Role $role) => $role->isOwnerRole()) && ! $actor->isOwner()) {
            throw new AuthorizationException(__('Only an owner can grant or revoke the owner role.'));
        }

        $this->permissionGrantGuard->authorize($actor, $changedRoles->flatMap(fn (Role $role) => $role->permissions->pluck('name')));

        if ($removedRoles->contains(fn (Role $role) => $role->isOwnerRole()) && ! $this->tenantHasAnotherOwner($staff)) {
            throw ValidationException::withMessages([
                'roles' => __('The car wash must keep at least one owner.'),
            ]);
        }

        DB::transaction(function () use ($actor, $staff, $newRoles, $addedRoles, $removedRoles): void {
            $staff->syncRoles($newRoles);

            $this->auditTrail->record('user.roles_synced', $staff, $actor, 'Staff roles changed', [
                'added' => $addedRoles->pluck('name')->values()->all(),
                'removed' => $removedRoles->pluck('name')->values()->all(),
            ]);
        });
    }

    /**
     * Only an active owner counts: a deactivated one cannot sign in to manage the car wash.
     */
    private function tenantHasAnotherOwner(User $staff): bool
    {
        return User::query()
            ->where('tenant_id', $staff->tenant_id)
            ->where('is_active', true)
            ->whereKeyNot($staff->getKey())
            ->whereHas('roles', fn ($query) => $query->where('key', DefaultRole::Owner->value))
            ->exists();
    }
}
