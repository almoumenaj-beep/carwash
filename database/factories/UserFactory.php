<?php

namespace Database\Factories;

use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'remember_token' => Str::random(10),
        ];
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }

    /**
     * Indicate that the user works for the given tenant, or a new one.
     */
    public function forTenant(?Tenant $tenant = null): static
    {
        return $this->state(fn (array $attributes) => [
            'tenant_id' => $tenant ?? Tenant::factory(),
        ]);
    }

    /**
     * Indicate that the user works in every branch of their tenant.
     */
    public function withAllBranches(): static
    {
        return $this->state(fn (array $attributes) => [
            'all_branches' => true,
        ]);
    }
}
