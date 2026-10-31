<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class MeEndpointTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    public function test_guests_are_unauthorized(): void
    {
        $this->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_staff_member_sees_their_roles_permissions_and_branches(): void
    {
        $tenant = $this->createTenantWithRoles();
        $ownBranch = Branch::factory()->for($tenant)->create();
        Branch::factory()->for($tenant)->create();
        $cashier = $this->createStaff($tenant, DefaultRole::Cashier, [$ownBranch]);
        Sanctum::actingAs($cashier);

        $expectedPermissions = collect(DefaultRole::Cashier->permissions())
            ->map(fn (Permission $permission) => $permission->value)
            ->sort()
            ->values()
            ->all();

        $this->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('data.id', $cashier->id)
            ->assertJsonPath('data.tenant.id', $tenant->id)
            ->assertJsonPath('data.is_owner', false)
            ->assertJsonPath('data.all_branches', false)
            ->assertJsonCount(1, 'data.roles')
            ->assertJsonPath('data.roles.0.key', DefaultRole::Cashier->value)
            ->assertJsonPath('data.permissions', $expectedPermissions)
            ->assertJsonCount(1, 'data.branches')
            ->assertJsonPath('data.branches.0.id', $ownBranch->id);
    }

    public function test_owner_holds_every_permission_and_every_branch(): void
    {
        $tenant = $this->createTenantWithRoles();
        Branch::factory()->count(2)->for($tenant)->create();
        Sanctum::actingAs($this->createStaff($tenant, DefaultRole::Owner));

        $this->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('data.is_owner', true)
            ->assertJsonPath('data.all_branches', true)
            ->assertJsonPath('data.permissions', Permission::values())
            ->assertJsonCount(2, 'data.branches');
    }

    public function test_role_labels_follow_the_accept_language_header(): void
    {
        $tenant = $this->createTenantWithRoles();
        Sanctum::actingAs($this->createStaff($tenant, DefaultRole::Cashier));

        $this->withHeader('Accept-Language', 'ar')
            ->getJson('/api/v1/me')
            ->assertJsonPath('data.roles.0.label', 'كاشير');

        $this->withHeader('Accept-Language', 'en-US,en;q=0.9')
            ->getJson('/api/v1/me')
            ->assertJsonPath('data.roles.0.label', 'Cashier');
    }
}
