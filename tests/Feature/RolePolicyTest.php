<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class RolePolicyTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
    }

    public function test_owner_manages_other_roles(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->enterTenant($this->tenant);
        $cashierRole = $this->defaultRoleOf($this->tenant, DefaultRole::Cashier);

        $this->assertTrue($owner->can('create', Role::class));
        $this->assertTrue($owner->can('update', $cashierRole));
        $this->assertTrue($owner->can('delete', $cashierRole));
    }

    public function test_owner_role_cannot_be_edited_or_deleted_even_by_an_owner(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->enterTenant($this->tenant);
        $ownerRole = $this->defaultRoleOf($this->tenant, DefaultRole::Owner);

        $this->assertTrue($owner->can('view', $ownerRole));
        $this->assertFalse($owner->can('update', $ownerRole));
        $this->assertFalse($owner->can('delete', $ownerRole));
    }

    public function test_staff_managers_may_view_but_not_edit_roles(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager);
        $this->enterTenant($this->tenant);
        $cashierRole = $this->defaultRoleOf($this->tenant, DefaultRole::Cashier);

        $this->assertTrue($manager->can('viewAny', Role::class));
        $this->assertTrue($manager->can('view', $cashierRole));
        $this->assertFalse($manager->can('create', Role::class));
        $this->assertFalse($manager->can('update', $cashierRole));
    }

    public function test_staff_without_roles_or_users_permission_cannot_see_roles(): void
    {
        $cashier = $this->createStaff($this->tenant, DefaultRole::Cashier);
        $this->enterTenant($this->tenant);

        $this->assertFalse($cashier->can('viewAny', Role::class));
    }

    public function test_roles_of_another_tenant_are_denied(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $otherTenant = $this->createTenantWithRoles();
        $this->enterTenant($this->tenant);
        $foreignRole = $this->defaultRoleOf($otherTenant, DefaultRole::Cashier);

        $this->assertFalse($owner->can('view', $foreignRole));
        $this->assertFalse($owner->can('update', $foreignRole));
    }
}
