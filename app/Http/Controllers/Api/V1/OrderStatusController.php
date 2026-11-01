<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Orders\Actions\ChangeOrderStatus;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Http\Controllers\Controller;
use App\Http\Requests\ChangeOrderStatusRequest;
use App\Http\Resources\OrderResource;

class OrderStatusController extends Controller
{
    /**
     * Move the order to another status (start, quality check, ready, delivered, cancel, or back for rework).
     */
    public function store(ChangeOrderStatusRequest $request, Order $order, ChangeOrderStatus $changeOrderStatus): OrderResource
    {
        $changeOrderStatus->handle(
            $request->user(),
            $order,
            OrderStatus::from($request->validated('status')),
            $request->validated('reason'),
        );

        return OrderResource::make($order->refresh()->load([
            'branch', 'customer', 'bay', 'staff', 'items', 'creator', 'statusHistory.user',
        ]));
    }
}
