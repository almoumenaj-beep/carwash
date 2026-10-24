<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class BranchPolicyTest extends TestCase
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

    public function test_staff_see_only_their_assigned_branches(): void
    {
        $cashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        $this->enterTenant($this->tenant);

        $this->assertTrue($cashier->can('view', $this->branchA));
        $this->assertFalse($cashier->can('view', $this->branchB));
    }

    public function test_owners_and_all_branch_staff_see_every_branch(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $accountant = $this->createStaff($this->tenant, DefaultRole::Accountant, allBranches: true);
        $this->enterTenant($this->tenant);

        $this->assertTrue($owner->can('view', $this->branchB));
        $this->assertTrue($accountant->can('view', $this->branchB));
    }

    public function test_changing_a_branch_requires_the_settings_permission(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]);
        $this->enterTenant($this->tenant);

        $this->assertTrue($owner->can('update', $this->branchA));
        $this->assertFalse($manager->can('update', $this->branchA));
        $this->assertFalse($manager->can('create', Branch::class));
    }

    public function test_branches_of_another_tenant_are_denied(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $foreignBranch = Branch::factory()->for(Tenant::factory())->create();
        $this->enterTenant($this->tenant);

        $this->assertFalse($owner->can('view', $foreignBranch));
    }
}
