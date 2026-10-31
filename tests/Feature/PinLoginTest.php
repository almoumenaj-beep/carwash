<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Database\Factories\DeviceFactory;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class PinLoginTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private Device $device;

    private User $cashier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->device = Device::factory()->for($this->tenant)->create();
        $this->cashier = $this->staffWithPin(DefaultRole::Cashier, '1111');
    }

    public function test_staff_switches_in_with_their_pin(): void
    {
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())
            ->assertOk()
            ->assertJsonPath('data.user.id', $this->cashier->id)
            ->assertJsonPath('data.device.id', $this->device->id)
            ->assertJsonMissingPath('data.device.secret');

        $this->assertSame($this->cashier->id, PersonalAccessToken::query()->sole()->tokenable_id);
    }

    public function test_switching_ends_the_previous_session_on_the_device(): void
    {
        $washer = $this->staffWithPin(DefaultRole::Washer, '2222');
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['user_id' => $washer->id, 'pin' => '2222']))->assertOk();

        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())->assertOk();

        $this->assertSame($this->cashier->id, PersonalAccessToken::query()->where('device_id', $this->device->id)->sole()->tokenable_id);
    }

    public function test_wrong_pin_is_rejected(): void
    {
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['pin' => '9999']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['pin' => 'The PIN is incorrect.']);
    }

    public function test_unknown_device_secret_is_rejected(): void
    {
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['device_secret' => 'guessed-secret']))
            ->assertUnauthorized();
    }

    public function test_revoked_device_cannot_switch_users(): void
    {
        $this->device->forceFill(['revoked_at' => now()])->save();

        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())->assertUnauthorized();
    }

    public function test_staff_of_another_car_wash_cannot_switch_in(): void
    {
        $outsider = User::factory()->forTenant()->withPin('1111')->create();

        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['user_id' => $outsider->id]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('pin');
    }

    public function test_deactivated_staff_cannot_switch_in(): void
    {
        $this->cashier->forceFill(['is_active' => false])->save();

        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())->assertForbidden();
    }

    public function test_pin_attempts_are_throttled(): void
    {
        foreach (range(1, 5) as $attempt) {
            $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['pin' => '9999']))->assertUnprocessable();
        }

        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())->assertTooManyRequests();
    }

    public function test_device_lists_only_staff_who_can_switch_in_on_it(): void
    {
        $this->createStaff($this->tenant, DefaultRole::Washer);
        $this->staffWithPin(DefaultRole::Washer, '3333')->forceFill(['is_active' => false])->save();
        User::factory()->forTenant()->withPin()->create();

        $this->postJson('/api/v1/auth/device-staff', $this->deviceCredentials())
            ->assertOk()
            ->assertExactJson(['data' => [['id' => $this->cashier->id, 'name' => $this->cashier->name]]]);
    }

    public function test_device_staff_list_requires_the_device_secret(): void
    {
        $this->postJson('/api/v1/auth/device-staff', $this->deviceCredentials(['device_secret' => 'guessed-secret']))
            ->assertUnauthorized();
    }

    private function staffWithPin(DefaultRole $defaultRole, string $pin): User
    {
        $user = $this->createStaff($this->tenant, $defaultRole);
        $user->forceFill(['pin_hash' => Hash::make($pin)])->save();

        return $user;
    }

    /**
     * @param  array<string, string>  $overrides
     * @return array<string, string>
     */
    private function deviceCredentials(array $overrides = []): array
    {
        return [
            'device_identifier' => $this->device->identifier,
            'device_secret' => DeviceFactory::SECRET,
            ...$overrides,
        ];
    }

    /**
     * @param  array<string, string>  $overrides
     * @return array<string, string>
     */
    private function pinCredentials(array $overrides = []): array
    {
        return $this->deviceCredentials([
            'user_id' => $this->cashier->id,
            'pin' => '1111',
            ...$overrides,
        ]);
    }
}
