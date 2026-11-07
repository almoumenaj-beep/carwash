<?php

namespace App\Domain\Memberships\Actions;

use App\Domain\Memberships\Models\CustomerMembership;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Validation\ValidationException;

/**
 * Takes one wash from a membership when an order is paid: it covers the dearest service on the order that the
 * membership includes, and add-ons it does not include are still paid for. Not on top of a discount or points.
 */
class UseMembershipWash
{
    /**
     * The locked membership and what it takes off the order.
     *
     * @param  array{discount_amount?: ?int, discount_percent_bps?: ?int, redeem_points?: ?int}  $data
     * @return array{membership: CustomerMembership, price: int}
     *
     * @throws ValidationException
     */
    public function handle(Tenant $tenant, Order $order, string $membershipId, array $data): array
    {
        if (! $tenant->memberships_enabled) {
            throw ValidationException::withMessages(['membership' => __('Memberships are turned off.')]);
        }

        if (! empty($data['discount_amount']) || ! empty($data['discount_percent_bps']) || ! empty($data['redeem_points'])) {
            throw ValidationException::withMessages(['membership' => __('A membership cannot be combined with a discount or points.')]);
        }

        $membership = CustomerMembership::query()->whereKey($membershipId)->lockForUpdate()->first();

        if ($membership === null || $order->customer_id === null || $membership->customer_id !== $order->customer_id) {
            throw ValidationException::withMessages(['membership' => __('This membership is not for this customer.')]);
        }

        if ($membership->vehicle_id !== null && $membership->vehicle_id !== $order->vehicle_id) {
            throw ValidationException::withMessages(['membership' => __('This membership is for another car.')]);
        }

        if (! $membership->isUsable()) {
            throw ValidationException::withMessages(['membership' => __('This membership has ended or has no washes left.')]);
        }

        $price = $order->items()
            ->whereNull('parent_id')
            ->whereIn('service_id', $membership->service_ids)
            ->where('unit_price', '>', 0)
            ->max('unit_price');

        if ($price === null) {
            throw ValidationException::withMessages(['membership' => __('This membership does not cover the services on this order.')]);
        }

        return ['membership' => $membership, 'price' => (int) $price];
    }
}
