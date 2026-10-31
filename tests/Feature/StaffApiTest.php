<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class StaffApiTest extends TestCase
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
        $this->branchA = Branch::factory()->for($this->tenant)->create(['name' => 'A Branch']);
        $this->branchB = Branch::factory()->for($this->tenant)->create(['name' => 'B Branch']);
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
    }

    public function test_owner_lists_every_staff_member_of_the_car_wash(): void
    {
        $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        $this->createStaff($this->createTenantWithRoles(), DefaultRole::Cashier);
        Sanctum::actingAs($this->owner);

        $this->getJson('/api/v1/users')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure(['data' => [['id', 'name', 'is_active', 'is_owner', 'has_pin', 'roles', 'branches']]]);
    }

    public function test_branch_manager_lists_only_staff_of_their_branches(): void
    {
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]);
        $ownCashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchB]);
        Sanctum::actingAs($manager);

        $ids = collect($this->getJson('/api/v1/users')->assertOk()->json('data'))->pluck('id');

        $this->assertEqualsCanonicalizing([$manager->id, $ownCashier->id], $ids->all());
    }

    public function test_staff_without_users_permission_cannot_list_staff(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]));

        $this->getJson('/api/v1/users')->assertForbidden();
    }

    public function test_owner_adds_a_staff_member_with_roles_and_branches(): void
    {
        Sanctum::actingAs($this->owner);

        $response = $this->postJson('/api/v1/users', [
            'name' => 'New Washer',
            'phone' => '0555555555',
            'password' => 'secret-password',
            'roles' => [$this->defaultRoleOf($this->tenant, DefaultRole::Washer)->id],
            'branch_ids' => [$this->branchB->id],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.name', 'New Washer')
            ->assertJsonPath('data.roles.0.key', DefaultRole::Washer->value)
            ->assertJsonPath('data.branches.0.id', $this->branchB->id);

        $staff = User::query()->findOrFail($response->json('data.id'));
        $this->assertSame($this->tenant->id, $staff->tenant_id);
        $this->assertTrue(Hash::check('secret-password', $staff->password));
        $this->assertDatabaseHas('activity_log', ['event' => 'user.created', 'subject_id' => $staff->id]);
    }

    public function test_a_staff_member_needs_an_email_or_a_phone(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/users', ['name' => 'Nobody', 'password' => 'secret-password', 'roles' => []])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'phone']);
    }

    public function test_emails_are_unique(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/users', ['name' => 'Copy', 'email' => $this->owner->email, 'password' => 'secret-password', 'roles' => []])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }

    public function test_branch_manager_cannot_grant_branches_beyond_their_own(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]));
        $payload = ['name' => 'Cashier', 'email' => 'c@example.com', 'password' => 'secret-password', 'roles' => []];

        $this->postJson('/api/v1/users', [...$payload, 'branch_ids' => [$this->branchB->id]])->assertForbidden();
        $this->postJson('/api/v1/users', [...$payload, 'all_branches' => true])->assertForbidden();
        $this->postJson('/api/v1/users', [...$payload, 'branch_ids' => [$this->branchA->id]])->assertCreated();
    }

    public function test_branches_of_another_car_wash_are_rejected(): void
    {
        $foreignBranch = Branch::factory()->for(Tenant::factory())->create();
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/users', [
            'name' => 'Cashier', 'email' => 'c@example.com', 'password' => 'secret-password', 'roles' => [],
            'branch_ids' => [$foreignBranch->id],
        ])->assertUnprocessable()->assertJsonValidationErrors('branch_ids.0');
    }

    public function test_nothing_is_created_when_a_role_cannot_be_granted(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branchA]));

        $this->postJson('/api/v1/users', [
            'name' => 'Payroll', 'email' => 'payroll@example.com', 'password' => 'secret-password',
            'roles' => [$this->defaultRoleOf($this->tenant, DefaultRole::Accountant)->id],
            'branch_ids' => [$this->branchA->id],
        ])->assertForbidden();

        $this->assertDatabaseMissing('users', ['email' => 'payroll@example.com']);
    }

    public function test_owner_updates_a_staff_member(): void
    {
        $cashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/users/{$cashier->id}", ['name' => 'Renamed', 'branch_ids' => [$this->branchB->id]])
            ->assertOk()
            ->assertJsonPath('data.name', 'Renamed')
            ->assertJsonCount(1, 'data.branches')
            ->assertJsonPath('data.branches.0.id', $this->branchB->id);
    }

    public function test_deactivating_a_staff_member_ends_their_sessions(): void
    {
        $cashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchA]);
        $cashier->createToken('tablet');
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/users/{$cashier->id}", ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->assertSame(0, $cashier->tokens()->count());
    }

    public function test_nobody_deactivates_their_own_account(): void
    {
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/users/{$this->owner->id}", ['is_active' => false])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('is_active');
    }

    public function test_branch_manager_cannot_edit_an_owner(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, allBranches: true));

        $this->patchJson("/api/v1/users/{$this->owner->id}", ['is_active' => false])->assertForbidden();
    }

    public function test_staff_of_another_car_wash_is_not_found(): void
    {
        $foreignStaff = $this->createStaff($this->createTenantWithRoles(), DefaultRole::Cashier);
        Sanctum::actingAs($this->owner);

        $this->getJson("/api/v1/users/{$foreignStaff->id}")->assertNotFound();
        $this->patchJson("/api/v1/users/{$foreignStaff->id}", ['name' => 'Hijacked'])->assertNotFound();
    }

    public function test_branch_list_shows_only_branches_the_user_works_in(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branchB]));

        $this->getJson('/api/v1/branches')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $this->branchB->id);
    }
}
