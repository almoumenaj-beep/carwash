<?php

namespace App\Domain\Orders\Actions;

use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Orders\Support\OrderAssignments;
use App\Domain\Orders\Support\OrderPricing;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Changes an order still in the queue: its bay, staff and notes, and its services (re-priced
 * from the catalog) until the car is ready.
 */
class UpdateOrder
{
    public function __construct(
        private OrderPricing $pricing,
        private OrderAssignments $assignments,
        private AuditTrail $auditTrail,
    ) {}

    /**
     * @param  array{items?: list<array{service_id: string, quantity?: int}>, bay_id?: ?string, staff_ids?: list<string>, notes?: ?string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, Order $order, array $data): Order
    {
        $order->loadMissing('branch', 'vehicleSize');

        if (isset($data['items']) && ! in_array($order->status, [OrderStatus::Waiting, OrderStatus::InProgress], true)) {
            throw ValidationException::withMessages(['items' => __('Services can only be changed before the car is ready.')]);
        }

        $priced = isset($data['items']) ? $this->pricing->price($order->branch, $order->vehicleSize, $data['items']) : null;

        if (array_key_exists('bay_id', $data)) {
            $bay = $this->assignments->bay($order->branch, $data['bay_id']);
            if ($order->status->occupiesBay()) {
                $this->assignments->ensureBayIsFree($order, $bay?->id);
            }
        }

        $staffIds = array_key_exists('staff_ids', $data) ? $this->assignments->staff($order->branch, $data['staff_ids']) : null;

        return DB::transaction(function () use ($actor, $order, $data, $priced, $staffIds): Order {
            if (array_key_exists('bay_id', $data)) {
                $order->bay_id = $data['bay_id'];
            }
            if (array_key_exists('notes', $data)) {
                $order->notes = $data['notes'];
            }
            if ($priced !== null) {
                $order->items()->delete();
                $order->items()->createMany($priced['lines']);
                $order->forceFill(['subtotal' => $priced['subtotal'], 'estimated_minutes' => min($priced['minutes'], 65535)]);
            }

            $order->save();

            if ($staffIds !== null) {
                $order->staff()->sync($staffIds);
            }

            if ($priced !== null) {
                $this->auditTrail->record('order.items_changed', $order, $actor, 'Order services changed', [
                    'subtotal' => $order->subtotal,
                    'items' => array_column($priced['lines'], 'name'),
                ]);
            }

            return $order;
        });
    }
}
