<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Platform\Actions\SaveBay;
use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreBayRequest;
use App\Http\Requests\UpdateBayRequest;
use App\Http\Resources\BayResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Wash bays of a branch. Taken out of service with is_active=false rather than deleted.
 */
class BayController extends Controller
{
    public function index(Branch $branch): AnonymousResourceCollection
    {
        Gate::authorize('view', $branch);

        return BayResource::collection($branch->bays()->orderBy('sort_order')->orderBy('name')->get());
    }

    public function store(StoreBayRequest $request, Branch $branch, SaveBay $saveBay): JsonResponse
    {
        return BayResource::make($saveBay->create($request->user(), $branch, $request->validated()))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function update(UpdateBayRequest $request, Bay $bay, SaveBay $saveBay): BayResource
    {
        return BayResource::make($saveBay->update($request->user(), $bay, $request->validated()));
    }
}
