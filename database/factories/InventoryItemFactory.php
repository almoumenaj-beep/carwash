<?php

namespace Database\Factories;

use App\Domain\Inventory\Models\InventoryItem;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InventoryItem>
 */
class InventoryItemFactory extends Factory
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
            'name' => fake()->unique()->randomElement(['Shampoo', 'Wax', 'Towels', 'Tyre shine', 'Glass cleaner']).' '.fake()->unique()->numberBetween(1, 9999),
            'unit' => 'L',
            'unit_cost' => 0,
            'min_stock_milli' => 0,
            'is_active' => true,
        ];
    }
}
