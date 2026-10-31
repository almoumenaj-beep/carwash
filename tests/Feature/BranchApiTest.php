<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class BranchApiTest extends TestCase
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

    public function test_owner_opens_a_branch_with_default_hours(): void
    {
        Sanctum::actingAs($this->owner);

        $response = $this->postJson('/api/v1/branches', ['name' => 'Riffa', 'code' => ' rif-1 ', 'phone' => '17000000']);

        $response->assertCreated()
            ->assertJsonPath('data.code', 'RIF-1')
            ->assertJsonPath('data.opening_hours.sat', ['opens' => '08:00', 'closes' => '22:00'])
            ->assertJsonPath('data.bays', []);
        $this->assertDatabaseHas('branches', ['code' => 'RIF-1', 'tenant_id' => $this->tenant->id]);
        $this->assertDatabaseHas('activity_log', ['event' => 'branch.created', 'subject_id' => $response->json('data.id')]);
    }

    public function test_opening_hours_accept_closed_days_and_late_closing(): void
    {
        Sanctum::actingAs($this->owner);
        $hours = [...Branch::defaultOpeningHours(), 'fri' => null, 'thu' => ['opens' => '16:00', 'closes' => '01:00']];

        $this->postJson('/api/v1/branches', ['name' => 'Seef', 'code' => 'SEEF', 'opening_hours' => $hours])
            ->assertCreated()
            ->assertJsonPath('data.opening_hours.fri', null)
            ->assertJsonPath('data.opening_hours.thu.closes', '01:00');
    }

    public function test_invalid_opening_hours_are_rejected(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/branches', [
            'name' => 'Seef',
            'code' => 'SEEF',
            'opening_hours' => ['sat' => ['opens' => '25:00', 'closes' => '10:00'], 'holiday' => null],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['opening_hours', 'opening_hours.sat']);
    }

    public function test_branch_codes_are_unique_within_the_car_wash(): void
    {
        Branch::factory()->for($this->tenant)->create(['code' => 'MAIN']);
        Branch::factory()->for(Tenant::factory())->create(['code' => 'SEEF']);
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/branches', ['name' => 'Copy', 'code' => 'main'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('code');
        $this->postJson('/api/v1/branches', ['name' => 'Seef', 'code' => 'SEEF'])->assertCreated();
    }

    public function test_a_creator_limited_to_some_branches_gets_access_to_the_new_one(): void
    {
        $settingsManager = $this->createStaffWithPermissions($this->tenant, [Permission::SettingsManage], allBranches: false);
        Sanctum::actingAs($settingsManager);

        $branchId = $this->postJson('/api/v1/branches', ['name' => 'Riffa', 'code' => 'RIF'])->assertCreated()->json('data.id');

        $this->getJson("/api/v1/branches/{$branchId}")->assertOk();
    }

    public function test_staff_without_settings_permission_cannot_open_or_edit_branches(): void
    {
        $branch = Branch::factory()->for($this->tenant)->create();
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, [$branch]));

        $this->postJson('/api/v1/branches', ['name' => 'Riffa', 'code' => 'RIF'])->assertForbidden();
        $this->patchJson("/api/v1/branches/{$branch->id}", ['name' => 'Renamed'])->assertForbidden();
    }

    public function test_owner_closes_a_branch_and_shows_it_with_its_bays(): void
    {
        $branch = Branch::factory()->for($this->tenant)->create();
        Bay::factory()->for($branch)->create(['name' => 'Bay 2', 'sort_order' => 2]);
        Bay::factory()->for($branch)->create(['name' => 'Bay 1', 'sort_order' => 1]);
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/branches/{$branch->id}", ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false)
            ->assertJsonPath('data.bays.0.name', 'Bay 1')
            ->assertJsonPath('data.bays.1.name', 'Bay 2');
    }

    public function test_staff_see_only_branches_they_work_in(): void
    {
        $ownBranch = Branch::factory()->for($this->tenant)->create();
        $otherBranch = Branch::factory()->for($this->tenant)->create();
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Cashier, [$ownBranch]));

        $this->getJson("/api/v1/branches/{$ownBranch->id}")->assertOk();
        $this->getJson("/api/v1/branches/{$otherBranch->id}")->assertForbidden();
    }

    public function test_branch_of_another_car_wash_is_not_found(): void
    {
        $foreignBranch = Branch::factory()->for(Tenant::factory())->create();
        Sanctum::actingAs($this->owner);

        $this->getJson("/api/v1/branches/{$foreignBranch->id}")->assertNotFound();
        $this->patchJson("/api/v1/branches/{$foreignBranch->id}", ['name' => 'Hijacked'])->assertNotFound();
    }
}
