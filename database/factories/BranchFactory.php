<?php

namespace Database\Factories;

use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Branch>
 */
class BranchFactory extends Factory
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
            'name' => fake()->city(),
            'code' => fake()->unique()->bothify('BR-###??'),
            'phone' => fake()->phoneNumber(),
            'address' => fake()->streetAddress(),
            'opening_hours' => Branch::defaultOpeningHours(),
            'is_active' => true,
        ];
    }

    /**
     * Indicate that the branch is closed.
     */
    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }
}
