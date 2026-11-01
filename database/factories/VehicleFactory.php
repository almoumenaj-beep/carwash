<?php

namespace Database\Factories;

use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Vehicle>
 */
class VehicleFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * Use `for($customer)`; the vehicle takes the customer's tenant.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'customer_id' => Customer::factory(),
            'tenant_id' => fn (array $attributes) => Customer::query()->withoutGlobalScopes()->find($attributes['customer_id'])->tenant_id,
            'plate_number' => fake()->unique()->numerify('######'),
            'vehicle_size_id' => null,
            'make' => fake()->randomElement(['Toyota', 'Nissan', 'Lexus', 'Kia', 'Hyundai']),
            'model' => fake()->randomElement(['Camry', 'Patrol', 'LX', 'Sportage', 'Elantra']),
            'color' => fake()->randomElement(['White', 'Black', 'Silver', 'Red']),
            'notes' => null,
        ];
    }
}
