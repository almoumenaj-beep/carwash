<?php

namespace Tests\Feature;

use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class UserIdentityTest extends TestCase
{
    use RefreshDatabase;

    public function test_users_are_identified_by_uuid(): void
    {
        $user = User::factory()->create();

        $this->assertTrue(Str::isUuid($user->id));
    }

    public function test_api_token_authenticates_a_uuid_user(): void
    {
        $user = User::factory()->forTenant()->create();
        $token = $user->createToken('device')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/user')
            ->assertOk()
            ->assertJsonPath('id', $user->id);
    }

    public function test_roles_are_scoped_to_the_current_tenant(): void
    {
        $tenantA = Tenant::factory()->create()->id;
        $tenantB = Tenant::factory()->create()->id;
        $user = User::factory()->create();

        setPermissionsTeamId($tenantA);
        $user->assignRole(Role::create(['name' => 'Cashier']));

        $this->assertTrue($user->hasRole('Cashier'));

        setPermissionsTeamId($tenantB);
        $user->unsetRelation('roles');

        $this->assertFalse($user->hasRole('Cashier'));
    }
}
