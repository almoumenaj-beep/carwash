<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Support\BranchAccessGuard;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Edits a staff account: profile, password, branch access and activation.
 * Deactivating ends all of the staff member's sessions at once.
 */
class UpdateStaffMember
{
    public function __construct(private BranchAccessGuard $branchAccessGuard, private AuditTrail $auditTrail) {}

    /**
     * @param  array{name?: string, email?: ?string, phone?: ?string, password?: ?string, is_active?: bool, all_branches?: bool, branch_ids?: list<string>}  $data
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function handle(User $actor, User $staff, array $data): User
    {
        if (($data['is_active'] ?? true) === false && $actor->is($staff)) {
            throw ValidationException::withMessages([
                'is_active' => __('You cannot deactivate your own account.'),
            ]);
        }

        $changesBranches = array_key_exists('all_branches', $data) || array_key_exists('branch_ids', $data);
        $allBranches = (bool) ($data['all_branches'] ?? $staff->all_branches);
        $branchIds = $allBranches ? [] : ($data['branch_ids'] ?? $staff->branches()->pluck('branches.id')->all());

        if ($changesBranches) {
            $this->branchAccessGuard->authorize($actor, $allBranches, $branchIds);
        }

        return DB::transaction(function () use ($actor, $staff, $data, $changesBranches, $allBranches, $branchIds): User {
            $staff->fill(array_intersect_key($data, array_flip(['name', 'email', 'phone'])));

            if (! empty($data['password'])) {
                $staff->password = $data['password'];
            }

            if (array_key_exists('is_active', $data)) {
                $staff->forceFill(['is_active' => $data['is_active']]);
            }

            if ($changesBranches) {
                $staff->forceFill(['all_branches' => $allBranches]);
                $staff->branches()->sync($branchIds);
            }

            $changed = array_keys($staff->getDirty());
            $staff->save();

            if ($staff->is_active === false) {
                $staff->tokens()->delete();
            }

            $this->auditTrail->record('user.updated', $staff, $actor, 'Staff member updated', [
                'changed' => array_values(array_diff($changed, ['password', 'updated_at'])),
                'password_changed' => in_array('password', $changed, true),
                'branches_changed' => $changesBranches,
            ]);

            return $staff;
        });
    }
}
