<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Platform\Actions\CreateBranch;
use App\Domain\Platform\Actions\UpdateBranch;
use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreBranchRequest;
use App\Http\Requests\UpdateBranchRequest;
use App\Http\Resources\BranchResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Branches of the car wash. Closed with is_active=false rather than deleted.
 */
class BranchController extends Controller
{
    /**
     * The branches the signed-in staff member works in.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Branch::class);

        return BranchResource::collection($request->user()->accessibleBranches());
    }

    public function store(StoreBranchRequest $request, CreateBranch $createBranch): JsonResponse
    {
        $branch = $createBranch->handle($request->user(), $request->validated());

        return BranchResource::make($this->withBays($branch))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    /**
     * A branch with its bays.
     */
    public function show(Branch $branch): BranchResource
    {
        Gate::authorize('view', $branch);

        return BranchResource::make($this->withBays($branch));
    }

    public function update(UpdateBranchRequest $request, Branch $branch, UpdateBranch $updateBranch): BranchResource
    {
        return BranchResource::make($this->withBays($updateBranch->handle($request->user(), $branch, $request->validated())));
    }

    private function withBays(Branch $branch): Branch
    {
        return $branch->load(['bays' => fn ($bays) => $bays->orderBy('sort_order')->orderBy('name')]);
    }
}
