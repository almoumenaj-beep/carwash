<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Resources\StaffSummaryResource;
use App\Models\User;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

/**
 * The active staff who work at a branch, for assigning washers to a car. Any staff member of the branch
 * may read it; managing staff stays behind users.manage.
 */
class BranchStaffController extends Controller
{
    public function __invoke(Branch $branch): AnonymousResourceCollection
    {
        Gate::authorize('view', $branch);

        $staff = User::query()
            ->where('tenant_id', $branch->tenant_id)
            ->where('is_active', true)
            ->with(['roles', 'branches:id'])
            ->orderBy('name')
            ->get()
            ->filter(fn (User $user) => $user->hasAllBranchAccess() || $user->branches->contains($branch))
            ->values();

        return StaffSummaryResource::collection($staff);
    }
}
