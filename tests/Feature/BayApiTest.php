<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class BayApiTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private Branch $branch;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->branch = Branch::factory()->for($this->tenant)->create();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
    }

    public function test_owner_adds_bays_which_go_to_the_end_of_the_list(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson("/api/v1/branches/{$this->branch->id}/bays", ['name' => 'Bay 1'])
            ->assertCreated()
            ->assertJsonPath('data.sort_order', 0)
            ->assertJsonPath('data.is_active', true);
        $this->postJson("/api/v1/branches/{$this->branch->id}/bays", ['name' => 'Detailing'])
            ->assertCreated()
            ->assertJsonPath('data.sort_order', 1);

        $this->getJson("/api/v1/branches/{$this->branch->id}/bays")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.1.name', 'Detailing');
    }

    public function test_bay_names_are_unique_within_a_branch_only(): void
    {
        Bay::factory()->for($this->branch)->create(['name' => 'Bay 1']);
        $otherBranch = Branch::factory()->for($this->tenant)->create();
        Sanctum::actingAs($this->owner);

        $this->postJson("/api/v1/branches/{$this->branch->id}/bays", ['name' => 'Bay 1'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('name');
        $this->postJson("/api/v1/branches/{$otherBranch->id}/bays", ['name' => 'Bay 1'])->assertCreated();
    }

    public function test_owner_renames_and_takes_a_bay_out_of_service(): void
    {
        $bay = Bay::factory()->for($this->branch)->create(['name' => 'Bay 1']);
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/bays/{$bay->id}", ['name' => 'Express', 'is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.name', 'Express')
            ->assertJsonPath('data.is_active', false);
        $this->assertDatabaseHas('activity_log', ['event' => 'bay.updated', 'subject_id' => $bay->id]);
    }

    public function test_staff_of_the_branch_see_its_bays_but_cannot_change_them(): void
    {
        $bay = Bay::factory()->for($this->branch)->create();
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branch]));

        $this->getJson("/api/v1/branches/{$this->branch->id}/bays")->assertOk()->assertJsonCount(1, 'data');
        $this->postJson("/api/v1/branches/{$this->branch->id}/bays", ['name' => 'Bay 9'])->assertForbidden();
        $this->patchJson("/api/v1/bays/{$bay->id}", ['name' => 'Renamed'])->assertForbidden();
    }

    public function test_bays_of_another_car_wash_are_not_found(): void
    {
        $foreignBay = Bay::factory()->for(Branch::factory()->for(Tenant::factory()))->create();
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/bays/{$foreignBay->id}", ['name' => 'Hijacked'])->assertNotFound();
        $this->getJson("/api/v1/branches/{$foreignBay->branch_id}/bays")->assertNotFound();
    }
}
