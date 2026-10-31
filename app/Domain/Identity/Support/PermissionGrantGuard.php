<?php

namespace App\Domain\Identity\Support;

use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

/**
 * Prevents privilege escalation: a user may only grant or revoke permissions they hold themselves.
 */
class PermissionGrantGuard
{
    /**
     * @param  iterable<string>  $changedPermissions
     *
     * @throws AuthorizationException
     */
    public function authorize(User $actor, iterable $changedPermissions): void
    {
        $missing = collect($changedPermissions)
            ->unique()
            ->diff($actor->permissionNames())
            ->sort()
            ->values();

        if ($missing->isNotEmpty()) {
            throw new AuthorizationException(__('You cannot grant or revoke permissions you do not have: :permissions', [
                'permissions' => $missing->implode(', '),
            ]));
        }
    }
}
