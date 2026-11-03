<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Catalog\Models\Service;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Inventory\Actions\SyncServiceMaterials;
use App\Domain\Inventory\Models\InventoryItem;
use App\Domain\Inventory\Support\Quantity;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

/**
 * What one sale of a service uses up (decimal quantities of each material's unit). Changed with services.manage.
 */
class ServiceMaterialController extends Controller
{
    public function show(Service $service): JsonResponse
    {
        Gate::authorize(Permission::ServicesManage->value);

        return response()->json(['data' => $this->present($service)]);
    }

    /**
     * Replace the service's materials.
     */
    public function update(Request $request, Service $service, SyncServiceMaterials $syncServiceMaterials): JsonResponse
    {
        Gate::authorize(Permission::ServicesManage->value);

        $validated = $request->validate([
            'materials' => ['present', 'array', 'max:30'],
            'materials.*.inventory_item_id' => [
                'required', 'uuid', 'distinct',
                Rule::exists('inventory_items', 'id')->where('tenant_id', $request->user()->tenant_id),
            ],
            'materials.*.quantity' => ['required', 'numeric', 'gt:0', 'max:100000', 'decimal:0,3'],
        ]);

        $syncServiceMaterials->handle($request->user(), $service, $validated['materials']);

        return response()->json(['data' => $this->present($service->load('materials'))]);
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function present(Service $service): array
    {
        return $service->materials->map(fn (InventoryItem $item) => [
            'inventory_item_id' => $item->id,
            'name' => $item->name,
            'unit' => $item->unit,
            'quantity' => Quantity::fromMilli($item->pivot->quantity_milli),
        ])->values()->all();
    }
}
