<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Database\Factories\DeviceFactory;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;
use Laravel\Sanctum\Sanctum;
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
        $this->device = Device::factory()->for($this->tenant)->create(['is_shared' => true]);
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

    public function test_a_personal_device_lists_nobody_and_refuses_switching(): void
    {
        $this->device->forceFill(['is_shared' => false])->save();

        $this->postJson('/api/v1/auth/device-staff', $this->deviceCredentials())->assertOk()->assertExactJson(['data' => []]);
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())->assertForbidden();
    }

    public function test_the_owner_never_switches_in_by_pin(): void
    {
        $owner = $this->staffWithPin(DefaultRole::Owner, '5827');

        $this->postJson('/api/v1/auth/device-staff', $this->deviceCredentials())
            ->assertOk()
            ->assertJsonMissing(['id' => $owner->id]);
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['user_id' => $owner->id, 'pin' => '5827']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('pin');
    }

    public function test_a_device_of_one_branch_only_offers_that_branchs_staff(): void
    {
        [$main, $other] = app(TenantContext::class)->run($this->tenant, fn () => [Branch::factory()->create(), Branch::factory()->create()]);
        $here = $this->createStaff($this->tenant, DefaultRole::Cashier, [$main]);
        $here->forceFill(['pin_hash' => Hash::make('5827')])->save();
        $elsewhere = $this->createStaff($this->tenant, DefaultRole::Cashier, [$other]);
        $elsewhere->forceFill(['pin_hash' => Hash::make('5827')])->save();
        $this->device->forceFill(['shared_branch_id' => $main->id])->save();

        $this->postJson('/api/v1/auth/device-staff', $this->deviceCredentials())
            ->assertJsonFragment(['id' => $here->id])
            ->assertJsonMissing(['id' => $elsewhere->id]);
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['user_id' => $elsewhere->id, 'pin' => '5827']))
            ->assertUnprocessable();
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['user_id' => $here->id, 'pin' => '5827']))
            ->assertOk()
            ->assertJsonPath('data.user.device_is_shared', true);
    }

    public function test_five_wrong_pins_lock_it_for_a_while_and_are_recorded(): void
    {
        foreach (range(1, 5) as $attempt) {
            $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['pin' => '9999']))->assertUnprocessable();
        }
        $this->withoutMiddleware(ThrottleRequests::class);

        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['pin' => 'Too many wrong attempts. Try again in 15 minutes.']);
        $this->assertDatabaseHas('activity_log', ['event' => 'user.pin_locked', 'subject_id' => $this->cashier->id]);

        $this->travel(16)->minutes();
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())->assertOk();
        $this->assertSame(0, $this->cashier->fresh()->pin_failed_attempts);
        $this->assertNull($this->cashier->fresh()->pin_locked_until);
    }

    public function test_a_right_pin_clears_the_wrong_attempts(): void
    {
        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials(['pin' => '9999']))->assertUnprocessable();
        $this->assertSame(1, $this->cashier->fresh()->pin_failed_attempts);

        $this->postJson('/api/v1/auth/pin-login', $this->pinCredentials())->assertOk();
        $this->assertSame(0, $this->cashier->fresh()->pin_failed_attempts);
    }

    public function test_easy_pins_are_refused_when_setting_one(): void
    {
        Sanctum::actingAs($this->cashier);

        foreach (['1111', '1234', '4321', '0123', '987654'] as $easy) {
            $this->putJson('/api/v1/me/pin', ['current_password' => 'password', 'pin' => $easy, 'pin_confirmation' => $easy])
                ->assertUnprocessable()
                ->assertJsonValidationErrors('pin');
        }
        $this->putJson('/api/v1/me/pin', ['current_password' => 'password', 'pin' => '5827', 'pin_confirmation' => '5827'])
            ->assertSuccessful();
    }

    public function test_managers_mark_a_device_as_shared_and_staff_cannot(): void
    {
        $this->device->forceFill(['is_shared' => false])->save();

        Sanctum::actingAs($this->cashier);
        $this->patchJson("/api/v1/devices/{$this->device->id}", ['is_shared' => true])->assertForbidden();

        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Owner));
        $this->patchJson("/api/v1/devices/{$this->device->id}", ['is_shared' => true])
            ->assertOk()
            ->assertJsonPath('data.is_shared', true);
        $this->assertDatabaseHas('activity_log', ['event' => 'device.sharing_changed', 'subject_id' => $this->device->id]);

        $this->patchJson("/api/v1/devices/{$this->device->id}", ['is_shared' => false])
            ->assertOk()
            ->assertJsonPath('data.is_shared', false);
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
