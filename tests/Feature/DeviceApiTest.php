<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Database\Factories\DeviceFactory;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class DeviceApiTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
    }

    public function test_owner_lists_the_devices_of_their_car_wash(): void
    {
        Device::factory()->count(2)->for($this->tenant)->create();
        Device::factory()->for(Tenant::factory())->create();
        Sanctum::actingAs($this->owner);

        $this->getJson('/api/v1/devices')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonMissingPath('data.0.secret_hash');
    }

    public function test_staff_without_users_permission_cannot_list_devices(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Cashier));

        $this->getJson('/api/v1/devices')->assertForbidden();
    }

    public function test_revoking_a_device_ends_its_session_and_blocks_pin_switching(): void
    {
        $device = Device::factory()->for($this->tenant)->create();
        $cashier = $this->createStaff($this->tenant, DefaultRole::Cashier);
        $cashier->createToken($device->name)->accessToken->forceFill(['device_id' => $device->id])->save();
        Sanctum::actingAs($this->owner);

        $this->deleteJson("/api/v1/devices/{$device->id}")->assertNoContent();

        $this->assertNotNull($device->fresh()->revoked_at);
        $this->assertSame(0, $device->tokens()->count());
        $this->assertDatabaseHas('activity_log', ['event' => 'device.revoked', 'subject_id' => $device->id, 'tenant_id' => $this->tenant->id]);
        $this->postJson('/api/v1/auth/device-staff', [
            'device_identifier' => $device->identifier,
            'device_secret' => DeviceFactory::SECRET,
        ])->assertUnauthorized();
    }

    public function test_device_of_another_car_wash_is_not_found(): void
    {
        $foreignDevice = Device::factory()->for(Tenant::factory())->create();
        Sanctum::actingAs($this->owner);

        $this->deleteJson("/api/v1/devices/{$foreignDevice->id}")->assertNotFound();
        $this->assertNull($foreignDevice->fresh()->revoked_at);
    }
}
