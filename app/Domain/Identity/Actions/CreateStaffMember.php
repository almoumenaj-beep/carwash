<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Support\BranchAccessGuard;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Adds a staff account to the actor's car wash with its roles and branches, all or nothing.
 */
class CreateStaffMember
{
    public function __construct(
        private BranchAccessGuard $branchAccessGuard,
        private SyncUserRoles $syncUserRoles,
        private AuditTrail $auditTrail,
    ) {}

    /**
     * @param  array{name: string, email?: ?string, phone?: ?string, password: string, roles: list<int>, all_branches?: bool, branch_ids?: list<string>}  $data
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function handle(User $actor, array $data): User
    {
        $allBranches = (bool) ($data['all_branches'] ?? false);
        $branchIds = $allBranches ? [] : ($data['branch_ids'] ?? []);

        $this->branchAccessGuard->authorize($actor, $allBranches, $branchIds);

        return DB::transaction(function () use ($actor, $data, $allBranches, $branchIds): User {
            $staff = new User([
                'name' => $data['name'],
                'email' => $data['email'] ?? null,
                'phone' => $data['phone'] ?? null,
                'password' => $data['password'],
            ]);
            $staff->forceFill(['tenant_id' => $actor->tenant_id, 'all_branches' => $allBranches])->save();
            $staff->branches()->sync($branchIds);

            $this->syncUserRoles->handle($actor, $staff, $data['roles']);

            $this->auditTrail->record('user.created', $staff, $actor, 'Staff member added', [
                'name' => $staff->name,
                'all_branches' => $allBranches,
                'branch_ids' => $branchIds,
            ]);

            return $staff;
        });
    }
}
