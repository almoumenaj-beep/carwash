<?php

namespace App\Domain\Orders\Actions;

use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Orders\Models\OrderItem;
use App\Domain\Orders\Support\OrderAssignments;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Moves a car along the queue. Only allowed transitions are accepted, a bay is used by one car
 * at a time, every step is stamped and recorded, and delivery counts as the customer's visit.
 * A car is handed over only once paid, and a paid order cannot be cancelled. Every inspection at
 * the quality check is recorded.
 */
class ChangeOrderStatus
{
    public function __construct(private OrderAssignments $assignments) {}

    /**
     * Leaving the quality check takes the inspection's results: to pass the car (ready) every service
     * on the order must be ticked as done properly; sending it back for rework records which were not.
     *
     * @param  list<array{item_id: string, passed: bool}>|null  $checklist
     *
     * @throws ValidationException
     */
    public function handle(User $actor, Order $order, OrderStatus $next, ?string $reason = null, ?array $checklist = null): Order
    {
        $current = $order->status;

        if ($next === OrderStatus::Delivered && $current->canMoveTo($next) && ! $order->isPaid()) {
            throw ValidationException::withMessages(['status' => __('Collect the payment before handing the car over.')]);
        }

        if ($next === OrderStatus::Cancelled && $order->isPaid()) {
            throw ValidationException::withMessages(['status' => __('A paid order cannot be cancelled; refund it instead.')]);
        }

        if (! $current->canMoveTo($next)) {
            throw ValidationException::withMessages(['status' => __('An order cannot move from :from to :to.', [
                'from' => __("order_status.{$current->value}"),
                'to' => __("order_status.{$next->value}"),
            ])]);
        }

        $inspection = $current === OrderStatus::QualityCheck ? $this->inspection($order, $next, $checklist) : null;

        if ($next->occupiesBay()) {
            $this->assignments->ensureBayIsFree($order, $order->bay_id);
        }

        return DB::transaction(function () use ($actor, $order, $current, $next, $reason, $inspection): Order {
            if ($inspection !== null) {
                $order->qualityChecks()->create([
                    'checked_by' => $actor->id,
                    'passed' => $next === OrderStatus::Ready,
                    'results' => $inspection,
                    'created_at' => now(),
                ]);
            }

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

    /**
     * Each service on the order with whether it was done properly, or null when nothing is recorded
     * (a car sent back without results). Passing the car needs every service ticked.
     *
     * @param  list<array{item_id: string, passed: bool}>|null  $checklist
     * @return list<array{item_id: string, name: string, passed: bool}>|null
     *
     * @throws ValidationException
     */
    private function inspection(Order $order, OrderStatus $next, ?array $checklist): ?array
    {
        $passed = collect($checklist ?? [])->mapWithKeys(fn (array $result) => [$result['item_id'] => (bool) $result['passed']]);
        $results = $order->items->map(fn (OrderItem $item) => [
            'item_id' => $item->id,
            'name' => $item->name,
            'passed' => $passed->get($item->id, false),
        ])->values()->all();

        if ($next === OrderStatus::Ready && in_array(false, array_column($results, 'passed'), true)) {
            throw ValidationException::withMessages(['checklist' => __('Tick every service on the order to pass the car.')]);
        }

        return $next === OrderStatus::Ready || $checklist !== null ? $results : null;
    }
}
