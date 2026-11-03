<?php

namespace App\Domain\Inventory\Actions;

use App\Domain\Catalog\Models\Service;
use App\Domain\Inventory\Support\Quantity;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Validation\ValidationException;

/**
 * Replaces what one sale of a service uses up. A package takes its materials from the services it
 * includes, so it has none of its own.
 */
class SyncServiceMaterials
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  list<array{inventory_item_id: string, quantity: int|float|string}>  $materials
     *
     * @throws ValidationException
     */
    public function handle(User $actor, Service $service, array $materials): Service
    {
        if ($service->is_package && $materials !== []) {
            throw ValidationException::withMessages(['materials' => __('A package uses the materials of the services it includes.')]);
        }

        $service->materials()->sync(collect($materials)->mapWithKeys(fn (array $material) => [
            $material['inventory_item_id'] => ['quantity_milli' => Quantity::toMilli($material['quantity'])],
        ])->all());

        $this->auditTrail->record('service.materials_changed', $service, $actor, 'Service materials changed', ['materials' => count($materials)]);

        return $service;
    }
}
