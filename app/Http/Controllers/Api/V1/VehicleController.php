<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Crm\Actions\DeleteCrmRecord;
use App\Domain\Crm\Actions\SaveVehicle;
use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Identity\Enums\Permission;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveVehicleRequest;
use App\Http\Resources\VehicleResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * A customer's cars: added under the customer, edited, transferred or deleted on their own.
 */
class VehicleController extends Controller
{
    public function store(SaveVehicleRequest $request, Customer $customer, SaveVehicle $saveVehicle): JsonResponse
    {
        return VehicleResource::make($saveVehicle->create($request->user(), $customer, $request->validated()))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function update(SaveVehicleRequest $request, Vehicle $vehicle, SaveVehicle $saveVehicle): VehicleResource
    {
        return VehicleResource::make($saveVehicle->update($request->user(), $vehicle, $request->validated()));
    }

    public function destroy(Request $request, Vehicle $vehicle, DeleteCrmRecord $deleteCrmRecord): Response
    {
        Gate::authorize(Permission::CustomersDelete->value);

        $deleteCrmRecord->handle($request->user(), $vehicle);

        return response()->noContent();
    }
}
