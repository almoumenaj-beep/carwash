<?php

namespace App\Domain\Orders\Support;

use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Validation\ValidationException;

/**
 * Checks the bay and staff given to an order: both must belong to the order's branch,
 * and a bay holds one car at a time while it is being worked on.
 */
class OrderAssignments
{
    /**
     * @throws ValidationException
     */
    public function bay(Branch $branch, ?string $bayId): ?Bay
    {
        if ($bayId === null) {
            return null;
        }

        return Bay::query()->where('branch_id', $branch->id)->where('is_active', true)->find($bayId)
            ?? throw ValidationException::withMessages(['bay_id' => __('Choose an active bay of this branch.')]);
    }

    /**
     * @param  list<string>  $userIds
     * @return list<string>
     *
     * @throws ValidationException
     */
    public function staff(Branch $branch, array $userIds): array
    {
        $staff = User::query()
            ->where('tenant_id', $branch->tenant_id)
            ->where('is_active', true)
            ->whereKey($userIds)
            ->get()
            ->filter(fn (User $user) => $user->canAccessBranch($branch));

        if ($staff->count() !== count(array_unique($userIds))) {
            throw ValidationException::withMessages(['staff_ids' => __('Assign only active staff of this branch.')]);
        }

        return $staff->modelKeys();
    }

    /**
     * @throws ValidationException
     */
    public function ensureBayIsFree(Order $order, ?string $bayId): void
    {
        if ($bayId === null) {
            return;
        }

        $busy = Order::query()
            ->where('bay_id', $bayId)
            ->whereKeyNot($order->getKey())
            ->whereIn('status', array_map(
                fn (OrderStatus $status) => $status->value,
                array_filter(OrderStatus::cases(), fn (OrderStatus $status) => $status->occupiesBay()),
            ))
            ->exists();

        if ($busy) {
            throw ValidationException::withMessages(['bay_id' => __('This bay is busy with another car.')]);
        }
    }
}
