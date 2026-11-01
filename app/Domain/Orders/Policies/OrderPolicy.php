<?php

namespace App\Domain\Orders\Policies;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Branch;
use App\Models\User;

/**
 * Work orders are handled by staff of their branch.
 */
class OrderPolicy
{
    /**
     * Seeing a branch's queue.
     */
    public function viewAny(User $user, Branch $branch): bool
    {
        return $user->can(Permission::OrdersView->value) && $user->canAccessBranch($branch);
    }

    public function view(User $user, Order $order): bool
    {
        return $user->can(Permission::OrdersView->value) && $user->canAccessBranch($order->branch);
    }

    /**
     * Checking a car in at a branch.
     */
    public function create(User $user, Branch $branch): bool
    {
        return $user->can(Permission::OrdersCreate->value) && $user->canAccessBranch($branch);
    }

    /**
     * Changing services, bay or staff; only while the car is still in the queue.
     */
    public function update(User $user, Order $order): bool
    {
        return $user->can(Permission::OrdersUpdate->value)
            && $order->status->isActive()
            && $user->canAccessBranch($order->branch);
    }

    /**
     * Moving the car along the queue; cancelling needs its own permission.
     */
    public function changeStatus(User $user, Order $order, OrderStatus $next): bool
    {
        $permission = $next === OrderStatus::Cancelled ? Permission::OrdersCancel : Permission::OrdersUpdateStatus;

        return $user->can($permission->value) && $user->canAccessBranch($order->branch);
    }
}
