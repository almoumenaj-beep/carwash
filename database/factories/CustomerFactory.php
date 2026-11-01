<?php

namespace Database\Factories;

use App\Domain\Crm\Models\Customer;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Customer>
 */
class CustomerFactory extends Factory
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
            'phone' => '+9733'.fake()->unique()->numerify('#######'),
            'name' => fake()->name(),
            'email' => null,
            'marketing_consent' => false,
            'notes' => null,
        ];
    }

    /**
     * Indicate that the customer agreed to receive marketing messages.
     */
    public function consenting(): static
    {
        return $this->state(fn (array $attributes) => [
            'marketing_consent' => true,
            'marketing_consent_at' => now(),
        ]);
    }
}
