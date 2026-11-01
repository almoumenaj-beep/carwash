<?php

namespace App\Domain\Crm\Actions;

use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;

/**
 * Adds a car to a customer or edits one. Setting another customer_id transfers the car,
 * e.g. after it was sold.
 */
class SaveVehicle
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{plate_number: string, vehicle_size_id?: ?string, make?: ?string, model?: ?string, color?: ?string, notes?: ?string}  $data
     */
    public function create(User $actor, Customer $customer, array $data): Vehicle
    {
        $vehicle = $customer->vehicles()->create($data);

        $this->auditTrail->record('vehicle.created', $vehicle, $actor, 'Vehicle added', [
            'plate_number' => $vehicle->plate_number,
            'customer_id' => $customer->id,
        ]);

        return $vehicle;
    }

    /**
     * @param  array{customer_id?: string, plate_number?: string, vehicle_size_id?: ?string, make?: ?string, model?: ?string, color?: ?string, notes?: ?string}  $data
     */
    public function update(User $actor, Vehicle $vehicle, array $data): Vehicle
    {
        $previousOwner = $vehicle->customer_id;
        $vehicle->fill($data);
        $changes = array_keys($vehicle->getDirty());

        if ($changes !== []) {
            $vehicle->save();

            $this->auditTrail->record('vehicle.updated', $vehicle, $actor, 'Vehicle updated', [
                'changed' => $changes,
                'transferred_from' => in_array('customer_id', $changes, true) ? $previousOwner : null,
            ]);
        }

        return $vehicle;
    }
}
