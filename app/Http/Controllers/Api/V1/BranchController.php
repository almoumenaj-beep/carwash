<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Resources\BranchResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

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
}
