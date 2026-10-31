<?php

namespace App\Domain\Identity\Support;

use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

/**
 * Prevents widening branch access: a user may only give staff access to branches they work in,
 * and only someone working in every branch may grant every branch.
 */
class BranchAccessGuard
{
    /**
     * @param  list<string>  $branchIds
     *
     * @throws AuthorizationException
     */
    public function authorize(User $actor, bool $allBranches, array $branchIds): void
    {
        if ($actor->hasAllBranchAccess()) {
            return;
        }

        $ownBranchIds = $actor->branches()->pluck('branches.id');

        if ($allBranches || collect($branchIds)->diff($ownBranchIds)->isNotEmpty()) {
            throw new AuthorizationException(__('You can only give access to branches you work in.'));
        }
    }
}
