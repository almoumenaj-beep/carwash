<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Orders\Models\Order;
use App\Domain\Sales\Actions\CheckoutOrder;
use App\Http\Controllers\Controller;
use App\Http\Requests\CheckoutOrderRequest;
use App\Http\Resources\OrderResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;

class OrderCheckoutController extends Controller
{
    /**
     * Take payment for the order and issue its invoice; the response is the order with the invoice
     * and the change to give back.
     */
    public function store(CheckoutOrderRequest $request, Order $order, CheckoutOrder $checkoutOrder): JsonResponse
    {
        $order = $checkoutOrder->handle($request->user(), $order, $request->validated());

        return OrderResource::make($order->refresh()->load([...OrderController::RELATIONS, 'statusHistory.user']))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }
}
