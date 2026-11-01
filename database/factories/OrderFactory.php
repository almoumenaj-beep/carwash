<?php

namespace Database\Factories;

use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * A bare order for tests that only need one to exist (e.g. "in use" checks). Real orders are
 * opened with the CheckInVehicle action, which prices and numbers them.
 *
 * @extends Factory<Order>
 */
class OrderFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * Use `for($branch)`; the order takes the branch's tenant.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'branch_id' => Branch::factory(),
            'tenant_id' => fn (array $attributes) => Branch::query()->withoutGlobalScopes()->find($attributes['branch_id'])->tenant_id,
            'number' => fake()->unique()->numberBetween(1, 999999),
            'plate_number' => fake()->numerify('#####'),
            'status' => OrderStatus::Waiting,
            'subtotal' => 0,
            'estimated_minutes' => 0,
            'created_by' => fn (array $attributes) => User::factory()->create(['tenant_id' => $attributes['tenant_id']])->id,
        ];
    }
}
