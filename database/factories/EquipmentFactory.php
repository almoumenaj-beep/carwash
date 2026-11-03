<?php

namespace Database\Factories;

use App\Domain\Equipment\Models\Equipment;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Equipment>
 */
class EquipmentFactory extends Factory
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
            'branch_id' => fn (array $attributes) => Branch::factory()->state(['tenant_id' => $attributes['tenant_id']]),
            'name' => fake()->randomElement(['Pressure washer', 'Vacuum', 'Compressor', 'Foam cannon']).' '.fake()->numberBetween(1, 99),
            'status' => 'in_service',
        ];
    }
}
