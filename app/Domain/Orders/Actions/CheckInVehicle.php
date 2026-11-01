<?php

namespace App\Domain\Orders\Actions;

use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Crm\Actions\SaveCustomer;
use App\Domain\Crm\Actions\SaveVehicle;
use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Orders\Support\OrderAssignments;
use App\Domain\Orders\Support\OrderPricing;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Opens a work order when a car arrives: a registered car (customer and size known) or a
 * walk-in plate, which is linked to its registered car when the plate is known. A walk-in who
 * gives a phone number is registered on the spot: the car is added to the customer with that
 * number, who is created when new. The order
 * number is the branch's next, taken under a lock so two counters never share a number.
 */
class CheckInVehicle
{
    public function __construct(
        private OrderPricing $pricing,
        private OrderAssignments $assignments,
        private SaveCustomer $saveCustomer,
        private SaveVehicle $saveVehicle,
    ) {}

    /**
     * @param  array{branch_id: string, vehicle_id?: ?string, plate_number?: ?string, vehicle_size_id?: ?string, customer_id?: ?string, customer_phone?: ?string, customer_name?: ?string, items: list<array{service_id: string, quantity?: int}>, bay_id?: ?string, staff_ids?: list<string>, notes?: ?string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, array $data): Order
    {
        $branch = Branch::query()->findOrFail($data['branch_id']);

        $vehicle = isset($data['vehicle_id'])
            ? Vehicle::query()->findOrFail($data['vehicle_id'])
            : Vehicle::query()->where('plate_number', $data['plate_number'])->first();

        $sizeId = $data['vehicle_size_id'] ?? $vehicle?->vehicle_size_id;
        $size = $sizeId === null ? null : VehicleSize::query()->find($sizeId);
        $priced = $this->pricing->price($branch, $size, $data['items']);
        $bay = $this->assignments->bay($branch, $data['bay_id'] ?? null);
        $staffIds = $this->assignments->staff($branch, $data['staff_ids'] ?? []);

        return DB::transaction(function () use ($actor, $data, $branch, $vehicle, $size, $priced, $bay, $staffIds): Order {
            if ($vehicle === null && filled($data['customer_phone'] ?? null)) {
                $vehicle = $this->registerWalkIn($actor, $data, $size);
            }

            Branch::query()->whereKey($branch->id)->lockForUpdate()->first();
            $number = (Order::query()->where('branch_id', $branch->id)->max('number') ?? 0) + 1;

            $order = new Order;
            $order->forceFill([
                'branch_id' => $branch->id,
                'number' => $number,
                'customer_id' => $vehicle?->customer_id ?? $data['customer_id'] ?? null,
                'vehicle_id' => $vehicle?->id,
                'plate_number' => $vehicle?->plate_number ?? $data['plate_number'] ?? null,
                'vehicle_size_id' => $size?->id,
                'bay_id' => $bay?->id,
                'status' => OrderStatus::Waiting,
                'subtotal' => $priced['subtotal'],
                'estimated_minutes' => min($priced['minutes'], 65535),
                'notes' => $data['notes'] ?? null,
                'created_by' => $actor->id,
            ])->save();

            $order->addItems($priced['lines']);
            $order->staff()->sync($staffIds);
            $order->statusHistory()->create([
                'from_status' => null,
                'to_status' => OrderStatus::Waiting,
                'user_id' => $actor->id,
                'created_at' => now(),
            ]);

            return $order;
        });
    }

    /**
     * Saves a walk-in's car under the customer with the phone number given, registering them when new.
     *
     * @param  array{plate_number: string, customer_phone: string, customer_name?: ?string}  $data
     */
    private function registerWalkIn(User $actor, array $data, ?VehicleSize $size): Vehicle
    {
        $name = $data['customer_name'] ?? null;
        $customer = Customer::query()->where('phone', $data['customer_phone'])->first();

        if ($customer === null) {
            $customer = $this->saveCustomer->create($actor, ['phone' => $data['customer_phone'], 'name' => $name]);
        } elseif (blank($customer->name) && filled($name)) {
            $this->saveCustomer->update($actor, $customer, ['name' => $name]);
        }

        return $this->saveVehicle->create($actor, $customer, [
            'plate_number' => $data['plate_number'],
            'vehicle_size_id' => $size?->id,
        ]);
    }
}
