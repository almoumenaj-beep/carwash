<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class RenameRole
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function handle(User $actor, Role $role, string $name): Role
    {
        $previousName = $role->name;

        if ($previousName === $name) {
            return $role;
        }

        return DB::transaction(function () use ($actor, $role, $name, $previousName): Role {
            $role->update(['name' => $name]);

            $this->auditTrail->record('role.renamed', $role, $actor, 'Role renamed', [
                'from' => $previousName,
                'to' => $name,
            ]);

            return $role;
        });
    }
}
