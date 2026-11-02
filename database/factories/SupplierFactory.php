<?php

namespace Database\Factories;

use App\Domain\Expenses\Models\Supplier;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Supplier>
 */
class SupplierFactory extends Factory
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
            'name' => fake()->unique()->company(),
            'phone' => null,
            'notes' => null,
            'is_active' => true,
        ];
    }
}
