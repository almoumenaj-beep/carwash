<?php

namespace Database\Factories;

use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Bay>
 */
class BayFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * Use `for($branch)`; the bay takes the branch's tenant.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'branch_id' => Branch::factory(),
            'tenant_id' => fn (array $attributes) => Branch::query()->withoutGlobalScopes()->find($attributes['branch_id'])->tenant_id,
            'name' => 'Bay '.fake()->unique()->numberBetween(1, 999),
            'sort_order' => 0,
            'is_active' => true,
        ];
    }

    /**
     * Indicate that the bay is out of service.
     */
    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }
}
