<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class UserPolicyTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private Branch $branchA;

    private Branch $branchB;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->branchA = Branch::factory()->for($this->tenant)->create();
        $this->branchB = Branch::factory()->for($this->tenant)->create();
    }

    public function test_branch_manager_manages_staff_of_their_branch(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]);
        $cashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        $this->enterTenant($this->tenant);

        $this->assertTrue($manager->can('view', $cashier));
        $this->assertTrue($manager->can('update', $cashier));
        $this->assertTrue($manager->can('delete', $cashier));
    }

    public function test_branch_manager_cannot_manage_staff_of_another_branch(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]);
        $cashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchB]);
        $this->enterTenant($this->tenant);

        $this->assertFalse($manager->can('view', $cashier));
        $this->assertFalse($manager->can('update', $cashier));
    }

    public function test_branch_manager_cannot_manage_staff_working_in_all_branches(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]);
        $accountant = $this->createStaff($this->tenant, DefaultRole::Accountant, allBranches: true);
        $this->enterTenant($this->tenant);

        $this->assertFalse($manager->can('update', $accountant));
    }

    public function test_only_an_owner_manages_an_owner(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $coOwner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, allBranches: true);
        $this->enterTenant($this->tenant);

        $this->assertFalse($manager->can('update', $owner));
        $this->assertTrue($coOwner->can('update', $owner));
    }

    public function test_nobody_deletes_their_own_account(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->enterTenant($this->tenant);

        $this->assertTrue($owner->can('update', $owner));
        $this->assertFalse($owner->can('delete', $owner));
    }

    public function test_staff_without_users_permission_cannot_manage_staff(): void
    {
        $cashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        $washer = $this->createStaff($this->tenant, DefaultRole::Washer, [$this->branchA]);
        $this->enterTenant($this->tenant);

        $this->assertFalse($cashier->can('viewAny', $washer::class));
        $this->assertFalse($cashier->can('update', $washer));
    }

    public function test_staff_of_another_tenant_are_denied(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $otherTenant = $this->createTenantWithRoles();
        $foreignCashier = $this->createStaff($otherTenant, DefaultRole::Cashier);
        $this->enterTenant($this->tenant);

        $this->assertFalse($owner->can('view', $foreignCashier));
        $this->assertFalse($owner->can('update', $foreignCashier));
    }
}
