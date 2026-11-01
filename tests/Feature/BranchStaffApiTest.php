<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class BranchStaffApiTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
    }

    public function test_staff_see_the_active_colleagues_of_their_branch_by_name_only(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->createStaff($this->tenant, DefaultRole::Washer, [$this->otherBranch]);
        $inactive = $this->createStaff($this->tenant, DefaultRole::Washer, [$this->branch]);
        $inactive->forceFill(['is_active' => false])->save();
        $this->createStaff($this->createTenantWithRoles(), DefaultRole::Owner);

        Sanctum::actingAs($this->washer);
        $response = $this->getJson("/api/v1/branches/{$this->branch->id}/staff")->assertOk();

        $this->assertEqualsCanonicalizing(
            [$owner->id, $this->cashier->id, $this->washer->id],
            array_column($response->json('data'), 'id'),
        );
        $this->assertSame(['id', 'name'], array_keys($response->json('data.0')));
    }

    public function test_staff_of_another_branch_cannot_list_it(): void
    {
        Sanctum::actingAs($this->washer);

        $this->getJson("/api/v1/branches/{$this->otherBranch->id}/staff")->assertForbidden();
    }
}
