<?php

namespace Database\Factories;

use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Device>
 */
class DeviceFactory extends Factory
{
    /**
     * The secret every factory device accepts unless a state overrides it.
     */
    public const SECRET = 'factory-device-secret';

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'tenant_id' => fn () => app(TenantContext::class)->id() ?? Tenant::factory(),
            'identifier' => (string) Str::uuid(),
            'name' => fake()->randomElement(['Front desk tablet', 'Cashier tablet', 'Manager phone']),
            'platform' => fake()->randomElement(['android', 'ios']),
            'secret_hash' => Device::hashSecret(self::SECRET),
            'last_login_at' => now(),
        ];
    }

    /**
     * Indicate that the device was revoked.
     */
    public function revoked(): static
    {
        return $this->state(fn (array $attributes) => [
            'revoked_at' => now(),
        ]);
    }
}
