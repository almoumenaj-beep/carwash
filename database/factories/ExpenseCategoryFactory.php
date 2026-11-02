<?php

namespace Database\Factories;

use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ExpenseCategory>
 */
class ExpenseCategoryFactory extends Factory
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
            'name' => fake()->unique()->randomElement(['Rent', 'Utilities', 'Supplies', 'Maintenance', 'Fuel']).' '.fake()->unique()->numberBetween(1, 9999),
            'sort_order' => 0,
            'is_active' => true,
        ];
    }
}
