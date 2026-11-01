<?php

namespace App\Domain\Orders\Actions;

use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Orders\Support\OrderAssignments;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Moves a car along the queue. Only allowed transitions are accepted, a bay is used by one car
 * at a time, every step is stamped and recorded, and delivery counts as the customer's visit.
 */
class ChangeOrderStatus
{
    public function __construct(private OrderAssignments $assignments) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Order $order, OrderStatus $next, ?string $reason = null): Order
    {
        $current = $order->status;

        if (! $current->canMoveTo($next)) {
            throw ValidationException::withMessages(['status' => __('An order cannot move from :from to :to.', [
                'from' => __("order_status.{$current->value}"),
                'to' => __("order_status.{$next->value}"),
            ])]);
        }

        if ($next->occupiesBay()) {
            $this->assignments->ensureBayIsFree($order, $order->bay_id);
        }

        return DB::transaction(function () use ($actor, $order, $current, $next, $reason): Order {
            $order->status = $next;

            if ($column = $next->timestampColumn()) {
                $order->{$column} = now();
            }
            if ($next === OrderStatus::Cancelled) {
                $order->cancel_reason = $reason;
            }

            $order->save();

            $order->statusHistory()->create([
                'from_status' => $current,
                'to_status' => $next,
                'user_id' => $actor->id,
                'reason' => $reason,
                'created_at' => now(),
            ]);

            if ($next === OrderStatus::Delivered && $order->customer !== null) {
                $order->customer->forceFill(['last_visit_at' => now()])->save();
            }

            return $order;
        });
    }
}
