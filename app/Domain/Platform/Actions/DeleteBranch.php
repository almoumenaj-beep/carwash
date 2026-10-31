<?php

namespace App\Domain\Platform\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Permanently removes a branch that was never used (e.g. created by mistake), together with
 * its bays, freeing its code. A branch in use can only be closed; the car wash keeps at least one.
 */
class DeleteBranch
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Branch $branch): void
    {
        if ($branch->isInUse()) {
            throw ValidationException::withMessages([
                'branch' => __('This branch is in use (staff are assigned to it). Close it instead of deleting it.'),
            ]);
        }

        if (Branch::query()->whereKeyNot($branch->getKey())->doesntExist()) {
            throw ValidationException::withMessages([
                'branch' => __('A car wash needs at least one branch.'),
            ]);
        }

        DB::transaction(function () use ($actor, $branch): void {
            $this->auditTrail->record('branch.deleted', $branch, $actor, 'Unused branch deleted', [
                'name' => $branch->name,
                'code' => $branch->code,
                'bays' => $branch->bays()->pluck('name')->all(),
            ]);

            $branch->bays()->delete();
            $branch->forceDelete();
        });
    }
}
