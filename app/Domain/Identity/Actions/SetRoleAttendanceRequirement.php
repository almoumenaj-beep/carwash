<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;

/**
 * Sets whether a role's staff must clock in before working.
 */
class SetRoleAttendanceRequirement
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function handle(User $actor, Role $role, bool $requiresAttendance): Role
    {
        if ($role->requires_attendance === $requiresAttendance) {
            return $role;
        }

        $role->forceFill(['requires_attendance' => $requiresAttendance])->save();

        $this->auditTrail->record('role.attendance_requirement_changed', $role, $actor, 'Role attendance requirement changed', [
            'requires_attendance' => $requiresAttendance,
        ]);

        return $role;
    }
}
