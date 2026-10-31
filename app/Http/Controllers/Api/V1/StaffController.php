<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\CreateStaffMember;
use App\Domain\Identity\Actions\UpdateStaffMember;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreStaffRequest;
use App\Http\Requests\UpdateStaffRequest;
use App\Http\Resources\StaffResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Staff accounts of the car wash. Accounts are deactivated rather than deleted, to keep their history.
 */
class StaffController extends Controller
{
    /**
     * Staff the signed-in manager may manage: everyone for all-branch managers, otherwise
     * the staff limited to branches they share.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', User::class);

        $actor = $request->user();

        $staff = User::query()
            ->where('tenant_id', $actor->tenant_id)
            ->unless($actor->hasAllBranchAccess(), fn ($query) => $query
                ->where('all_branches', false)
                ->whereHas('branches', fn ($branches) => $branches->whereIn('branches.id', $actor->branches()->select('branches.id'))))
            ->with(['roles', 'branches'])
            ->orderBy('name')
            ->orderBy('id')
            ->cursorPaginate(50);

        return StaffResource::collection($staff);
    }

    public function store(StoreStaffRequest $request, CreateStaffMember $createStaffMember): JsonResponse
    {
        $staff = $createStaffMember->handle($request->user(), $request->validated());

        return StaffResource::make($staff->load(['roles', 'branches']))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function show(User $user): StaffResource
    {
        Gate::authorize('view', $user);

        return StaffResource::make($user->load(['roles', 'branches']));
    }

    public function update(UpdateStaffRequest $request, User $user, UpdateStaffMember $updateStaffMember): StaffResource
    {
        $updateStaffMember->handle($request->user(), $user, $request->validated());

        return StaffResource::make($user->load(['roles', 'branches']));
    }
}
