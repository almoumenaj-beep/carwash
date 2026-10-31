<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class UserRoleApiTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private Branch $branchA;

    private Branch $branchB;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->branchA = Branch::factory()->for($this->tenant)->create();
        $this->branchB = Branch::factory()->for($this->tenant)->create();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
    }

    public function test_owner_assigns_roles_to_staff(): void
    {
        $staff = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        Sanctum::actingAs($this->owner);

        $this->putJson("/api/v1/users/{$staff->id}/roles", ['roles' => $this->roleIds(DefaultRole::Cashier, DefaultRole::Washer)])
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->enterTenant($this->tenant);
        $this->assertEqualsCanonicalizing(
            [DefaultRole::Cashier->value, DefaultRole::Washer->value],
            $staff->fresh()->roles->pluck('key')->all(),
        );
        $this->assertDatabaseHas('activity_log', [
            'event' => 'user.roles_synced',
            'tenant_id' => $this->tenant->id,
            'subject_id' => $staff->id,
        ]);
    }

    public function test_roles_of_another_tenant_cannot_be_assigned(): void
    {
        $staff = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        $foreignRole = $this->defaultRoleOf($this->createTenantWithRoles(), DefaultRole::Washer);
        Sanctum::actingAs($this->owner);

        $this->putJson("/api/v1/users/{$staff->id}/roles", ['roles' => [$foreignRole->id]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('roles.0');
    }

    public function test_branch_manager_assigns_roles_within_their_own_permissions(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]);
        $staff = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        Sanctum::actingAs($manager);

        $this->putJson("/api/v1/users/{$staff->id}/roles", ['roles' => $this->roleIds(DefaultRole::Washer)])
            ->assertOk();
    }

    public function test_branch_manager_cannot_assign_a_role_with_permissions_they_lack(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]);
        $staff = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        Sanctum::actingAs($manager);

        $this->putJson("/api/v1/users/{$staff->id}/roles", ['roles' => $this->roleIds(DefaultRole::Accountant)])
            ->assertForbidden();
    }

    public function test_only_an_owner_grants_the_owner_role(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, allBranches: true);
        $staff = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        Sanctum::actingAs($manager);

        $this->putJson("/api/v1/users/{$staff->id}/roles", ['roles' => $this->roleIds(DefaultRole::Owner)])
            ->assertForbidden()
            ->assertJsonPath('message', 'Only an owner can grant or revoke the owner role.');
    }

    public function test_branch_manager_cannot_change_roles_of_staff_in_another_branch(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]);
        $staff = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchB]);
        Sanctum::actingAs($manager);

        $this->putJson("/api/v1/users/{$staff->id}/roles", ['roles' => $this->roleIds(DefaultRole::Washer)])
            ->assertForbidden();
    }

    public function test_the_last_owner_keeps_the_owner_role(): void
    {
        Sanctum::actingAs($this->owner);

        $this->putJson("/api/v1/users/{$this->owner->id}/roles", ['roles' => $this->roleIds(DefaultRole::Cashier)])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('roles');
    }

    public function test_an_owner_steps_down_when_another_owner_remains(): void
    {
        $this->createStaff($this->tenant, DefaultRole::Owner);
        Sanctum::actingAs($this->owner);

        $this->putJson("/api/v1/users/{$this->owner->id}/roles", ['roles' => $this->roleIds(DefaultRole::Cashier)])
            ->assertOk()
            ->assertJsonPath('data.0.key', DefaultRole::Cashier->value);
    }

    public function test_staff_of_another_tenant_is_not_found(): void
    {
        $foreignStaff = $this->createStaff($this->createTenantWithRoles(), DefaultRole::Cashier);
        Sanctum::actingAs($this->owner);

        $this->putJson("/api/v1/users/{$foreignStaff->id}/roles", ['roles' => []])->assertNotFound();
    }

    /**
     * @return list<int>
     */
    private function roleIds(DefaultRole ...$defaultRoles): array
    {
        return array_map(fn (DefaultRole $defaultRole) => $this->defaultRoleOf($this->tenant, $defaultRole)->id, $defaultRoles);
    }
}
