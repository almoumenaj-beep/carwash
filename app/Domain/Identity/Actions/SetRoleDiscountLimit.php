<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Validation\ValidationException;

/**
 * Sets the largest discount a role may give. Like permissions, nobody may allow more than they
 * may give themselves.
 */
class SetRoleDiscountLimit
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Role $role, int $maxDiscountBps): Role
    {
        $previous = $role->max_discount_bps;

        if ($previous === $maxDiscountBps) {
            return $role;
        }

        if ($maxDiscountBps > $actor->maxDiscountBps()) {
            throw ValidationException::withMessages([
                'max_discount_bps' => __('You cannot allow a larger discount than your own (:limit%).', [
                    'limit' => $actor->maxDiscountBps() / 100,
                ]),
            ]);
        }

        $role->forceFill(['max_discount_bps' => $maxDiscountBps])->save();

        $this->auditTrail->record('role.discount_limit_changed', $role, $actor, 'Role discount limit changed', [
            'from' => $previous,
            'to' => $maxDiscountBps,
        ]);

        return $role;
    }
}
