<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Catalog\Actions\DeleteCatalogEntry;
use App\Domain\Catalog\Actions\SaveCatalogEntry;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Identity\Enums\Permission;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveVehicleSizeRequest;
use App\Http\Resources\VehicleSizeResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Vehicle sizes that prices depend on. Readable by all staff; changed with services.manage.
 */
class VehicleSizeController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return VehicleSizeResource::collection(VehicleSize::query()->orderBy('sort_order')->orderBy('name')->get());
    }

    public function store(SaveVehicleSizeRequest $request, SaveCatalogEntry $saveCatalogEntry): JsonResponse
    {
        return VehicleSizeResource::make($saveCatalogEntry->create($request->user(), VehicleSize::class, $request->validated()))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function update(SaveVehicleSizeRequest $request, VehicleSize $vehicleSize, SaveCatalogEntry $saveCatalogEntry): VehicleSizeResource
    {
        return VehicleSizeResource::make($saveCatalogEntry->update($request->user(), $vehicleSize, $request->validated()));
    }

    /**
     * Delete a size together with its prices; the last size cannot be deleted.
     */
    public function destroy(Request $request, VehicleSize $vehicleSize, DeleteCatalogEntry $deleteCatalogEntry): Response
    {
        Gate::authorize(Permission::ServicesManage->value);

        $deleteCatalogEntry->handle($request->user(), $vehicleSize);

        return response()->noContent();
    }
}
