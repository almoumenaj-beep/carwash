<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Catalog\Actions\DeleteCatalogEntry;
use App\Domain\Catalog\Actions\SaveService;
use App\Domain\Catalog\Models\Service;
use App\Domain\Identity\Enums\Permission;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveServiceRequest;
use App\Http\Resources\ServiceResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * The service menu with prices. Readable by all staff (the POS needs it); changed with services.manage.
 */
class ServiceController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return ServiceResource::collection(
            Service::query()->with('prices')->orderBy('is_addon')->orderBy('sort_order')->orderBy('name')->get(),
        );
    }

    public function store(SaveServiceRequest $request, SaveService $saveService): JsonResponse
    {
        return ServiceResource::make($saveService->create($request->user(), $request->validated())->load('prices'))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function show(Service $service): ServiceResource
    {
        return ServiceResource::make($service->load('prices'));
    }

    public function update(SaveServiceRequest $request, Service $service, SaveService $saveService): ServiceResource
    {
        return ServiceResource::make($saveService->update($request->user(), $service, $request->validated())->load('prices'));
    }

    /**
     * Delete a service that was never sold, with its prices; sold services are deactivated instead.
     */
    public function destroy(Request $request, Service $service, DeleteCatalogEntry $deleteCatalogEntry): Response
    {
        Gate::authorize(Permission::ServicesManage->value);

        $deleteCatalogEntry->handle($request->user(), $service);

        return response()->noContent();
    }
}
