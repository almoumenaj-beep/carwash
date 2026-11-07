<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;

/**
 * Changes a staff member's own password, once they confirmed the current one. Does not end their
 * other sessions, unlike deactivating an account.
 */
class SetOwnPassword
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function handle(User $user, string $password): void
    {
        $user->forceFill(['password' => $password])->save();

        $this->auditTrail->record('user.password_changed', $user, $user, 'Password changed');
    }
}
