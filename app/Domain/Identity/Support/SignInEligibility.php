<?php

namespace App\Domain\Identity\Support;

use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

/**
 * Whether a staff member may use the app: linked to an active car wash and not deactivated.
 * Checked at sign-in and on every authenticated API request.
 */
class SignInEligibility
{
    /**
     * @throws AuthorizationException
     */
    public function ensure(User $user): void
    {
        if ($user->tenant === null) {
            throw new AuthorizationException(__('This account is not linked to a car wash.'));
        }

        if (! $user->tenant->isActive()) {
            throw new AuthorizationException(__('This car wash account is suspended.'));
        }

        if ($user->is_active === false) {
            throw new AuthorizationException(__('This account is deactivated.'));
        }
    }
}
