<?php

namespace Database\Factories;

use App\Domain\Catalog\Models\Service;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Service>
 */
class ServiceFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'tenant_id' => fn () => app(TenantContext::class)->id() ?? Tenant::factory(),
            'service_category_id' => null,
            'name' => fake()->unique()->words(3, true),
            'description' => null,
            'duration_minutes' => fake()->randomElement([15, 20, 30, 45, 60]),
            'is_addon' => false,
            'sort_order' => 0,
            'is_active' => true,
        ];
    }

    /**
     * Indicate that the service is an add-on sold with a main service.
     */
    public function addon(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_addon' => true,
        ]);
    }
}
