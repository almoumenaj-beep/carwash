<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Enums\TenantStatus;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class PasswordLoginTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private User $cashier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->cashier = $this->createStaff($this->tenant, DefaultRole::Cashier);
        $this->cashier->forceFill(['email' => 'cashier@example.com', 'phone' => '0500000002'])->save();
    }

    public function test_staff_signs_in_with_email_and_gets_a_device_session(): void
    {
        $response = $this->postJson('/api/v1/auth/login', $this->credentials());

        $response->assertOk()
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonPath('data.user.id', $this->cashier->id)
            ->assertJsonPath('data.user.roles.0.key', DefaultRole::Cashier->value);
        $this->assertNotEmpty($response->json('data.device.secret'));

        $device = Device::query()->withoutGlobalScopes()->sole();
        $this->assertSame($this->tenant->id, $device->tenant_id);
        $this->assertTrue($device->matchesSecret($response->json('data.device.secret')));
        $this->assertSame($device->id, PersonalAccessToken::query()->sole()->device_id);

        $this->withToken($response->json('data.token'))->getJson('/api/v1/me')->assertOk();
    }

    public function test_staff_signs_in_with_phone(): void
    {
        $this->postJson('/api/v1/auth/login', $this->credentials(['login' => '0500000002']))
            ->assertOk()
            ->assertJsonPath('data.user.id', $this->cashier->id);
    }

    public function test_wrong_password_is_rejected(): void
    {
        $this->postJson('/api/v1/auth/login', $this->credentials(['password' => 'wrong-password']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['login' => 'These credentials do not match our records.']);
    }

    public function test_unknown_account_is_rejected_the_same_way(): void
    {
        $this->postJson('/api/v1/auth/login', $this->credentials(['login' => 'nobody@example.com']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['login' => 'These credentials do not match our records.']);
    }

    public function test_deactivated_staff_cannot_sign_in(): void
    {
        $this->cashier->forceFill(['is_active' => false])->save();

        $this->postJson('/api/v1/auth/login', $this->credentials())
            ->assertForbidden()
            ->assertJsonPath('detail', 'This account is deactivated.');
    }

    public function test_staff_of_a_suspended_car_wash_cannot_sign_in(): void
    {
        $this->tenant->forceFill(['status' => TenantStatus::Suspended])->save();

        $this->postJson('/api/v1/auth/login', $this->credentials())
            ->assertForbidden()
            ->assertJsonPath('detail', 'This car wash account is suspended.');
    }

    public function test_a_new_sign_in_on_the_device_ends_the_previous_session(): void
    {
        $firstToken = $this->postJson('/api/v1/auth/login', $this->credentials())->json('data.token');
        $this->postJson('/api/v1/auth/login', $this->credentials())->assertOk();

        $this->assertSame(1, PersonalAccessToken::query()->count());
        $this->app['auth']->forgetGuards();
        $this->withToken($firstToken)->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_sign_in_attempts_are_throttled(): void
    {
        foreach (range(1, 5) as $attempt) {
            $this->postJson('/api/v1/auth/login', $this->credentials(['password' => 'wrong-password']))->assertUnprocessable();
        }

        $this->postJson('/api/v1/auth/login', $this->credentials())->assertTooManyRequests();
    }

    public function test_tokens_of_deactivated_staff_stop_working(): void
    {
        $token = $this->postJson('/api/v1/auth/login', $this->credentials())->json('data.token');

        $this->cashier->forceFill(['is_active' => false])->save();
        $this->app['auth']->forgetGuards();

        $this->withToken($token)->getJson('/api/v1/me')->assertForbidden();
    }

    public function test_logout_ends_the_session(): void
    {
        $token = $this->postJson('/api/v1/auth/login', $this->credentials())->json('data.token');

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertNoContent();

        $this->assertSame(0, PersonalAccessToken::query()->count());
        $this->app['auth']->forgetGuards();
        $this->withToken($token)->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_staff_sets_their_pin_with_their_current_password(): void
    {
        Sanctum::actingAs($this->cashier);

        $this->putJson('/api/v1/me/pin', ['current_password' => 'password', 'pin' => '4321', 'pin_confirmation' => '4321'])
            ->assertNoContent();

        $this->assertTrue(Hash::check('4321', $this->cashier->fresh()->pin_hash));
    }

    public function test_setting_a_pin_requires_the_current_password(): void
    {
        Sanctum::actingAs($this->cashier);

        $this->putJson('/api/v1/me/pin', ['current_password' => 'wrong-password', 'pin' => '4321', 'pin_confirmation' => '4321'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('current_password');
        $this->assertNull($this->cashier->fresh()->pin_hash);
    }

    public function test_pin_must_be_four_to_six_digits(): void
    {
        Sanctum::actingAs($this->cashier);

        $this->putJson('/api/v1/me/pin', ['current_password' => 'password', 'pin' => '12a', 'pin_confirmation' => '12a'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('pin');
    }

    /**
     * @param  array<string, string>  $overrides
     * @return array<string, string>
     */
    private function credentials(array $overrides = []): array
    {
        return [
            'login' => 'cashier@example.com',
            'password' => 'password',
            'device_identifier' => 'tablet-1',
            'device_name' => 'Front desk tablet',
            'platform' => 'android',
            ...$overrides,
        ];
    }
}
