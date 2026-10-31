<?php

namespace Database\Factories;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServicePrice;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ServicePrice>
 */
class ServicePriceFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * Use `for($service)`; the price takes the service's tenant.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'service_id' => Service::factory(),
            'tenant_id' => fn (array $attributes) => Service::query()->withoutGlobalScopes()->find($attributes['service_id'])->tenant_id,
            'vehicle_size_id' => null,
            'branch_id' => null,
            'price' => fake()->numberBetween(1, 20) * 500,
        ];
    }
}
