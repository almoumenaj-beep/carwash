<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Orders\Actions\CheckInVehicle;
use App\Domain\Orders\Actions\UpdateOrder;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreOrderRequest;
use App\Http\Requests\UpdateOrderRequest;
use App\Http\Resources\OrderResource;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Work orders of a branch: the live queue, check-in and edits.
 */
class OrderController extends Controller
{
    /**
     * The relations every order response shows.
     *
     * @var list<string>
     */
    private const RELATIONS = ['branch', 'customer', 'bay', 'staff', 'items', 'creator'];

    /**
     * A branch's queue: `scope=active` (default) is every car still in the wash, oldest first;
     * `scope=today` is everything checked in today (the car wash's time zone), newest first.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'scope' => ['sometimes', 'in:active,today'],
        ]);

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('viewAny', [Order::class, $branch]);

        $today = $request->input('scope') === 'today';
        $timezone = $request->user()->tenant->timezone;

        $orders = Order::query()
            ->where('branch_id', $branch->id)
            ->when(
                $today,
                fn (Builder $query) => $query->where('created_at', '>=', now($timezone)->startOfDay()->utc())->latest()->orderByDesc('number'),
                fn (Builder $query) => $query->whereIn('status', OrderStatus::activeValues())->oldest()->orderBy('number'),
            )
            ->with(self::RELATIONS)
            ->limit(200)
            ->get();

        return OrderResource::collection($orders);
    }

    public function store(StoreOrderRequest $request, CheckInVehicle $checkInVehicle): JsonResponse
    {
        $order = $checkInVehicle->handle($request->user(), $request->validated());

        return OrderResource::make($order->load(self::RELATIONS))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    /**
     * An order with its status history.
     */
    public function show(Order $order): OrderResource
    {
        Gate::authorize('view', $order);

        return OrderResource::make($order->load([...self::RELATIONS, 'statusHistory.user']));
    }

    public function update(UpdateOrderRequest $request, Order $order, UpdateOrder $updateOrder): OrderResource
    {
        $updateOrder->handle($request->user(), $order, $request->validated());

        return OrderResource::make($order->refresh()->load([...self::RELATIONS, 'statusHistory.user']));
    }
}
