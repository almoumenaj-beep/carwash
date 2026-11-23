<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Support\BranchAccessGuard;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Staff\Enums\CommissionType;
use App\Domain\Staff\Models\EmployeeProfile;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
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
     * @param  array{name: string, email?: ?string, phone?: ?string, password: string, pin?: ?string, roles: list<int>, all_branches?: bool, branch_ids?: list<string>, salary_type?: SalaryType, monthly_salary?: int}  $data
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
            $staff->forceFill([
                'tenant_id' => $actor->tenant_id,
                'all_branches' => $allBranches,
                'pin_hash' => empty($data['pin']) ? null : Hash::make($data['pin']),
            ])->save();
            $staff->branches()->sync($branchIds);

            $this->syncUserRoles->handle($actor, $staff, $data['roles']);

            // Optional pay terms chosen on the form: without them the employee keeps the
            // default profile (monthly, zero salary) until set in staff affairs.
            if (isset($data['salary_type'])) {
                EmployeeProfile::query()->create([
                    'user_id' => $staff->id,
                    'monthly_salary' => (int) ($data['monthly_salary'] ?? 0),
                    'salary_type' => $data['salary_type'],
                    'commission_type' => CommissionType::None,
                    'commission_value' => 0,
                ]);
            }

            $this->auditTrail->record('user.created', $staff, $actor, 'Staff member added', [
                'name' => $staff->name,
                'all_branches' => $allBranches,
                'branch_ids' => $branchIds,
                'has_pin' => $staff->hasPin(),
            ]);

            return $staff;
        });
    }
}
