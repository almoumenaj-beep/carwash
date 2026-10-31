<?php

namespace Tests\Feature;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServiceCategory;
use App\Domain\Catalog\Models\ServicePrice;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

/**
 * Vehicle sizes and service categories, and tenant provisioning of default sizes.
 */
class CatalogSetupApiTest extends TestCase
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

    public function test_provisioning_gives_a_tenant_default_sizes_in_its_language_once(): void
    {
        $this->artisan('tenants:provision-defaults')->assertSuccessful();
        $this->artisan('tenants:provision-defaults')->assertSuccessful();

        $this->enterTenant($this->tenant);
        $this->assertSame(['صغيرة', 'سيدان', 'دفع رباعي (SUV)', 'فان / شاحنة'], VehicleSize::query()->orderBy('sort_order')->pluck('name')->all());
    }

    public function test_every_staff_member_reads_sizes_and_categories(): void
    {
        $this->enterTenant($this->tenant);
        VehicleSize::factory()->create(['name' => 'Sedan']);
        ServiceCategory::factory()->create(['name' => 'Wash']);
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Washer));

        $this->getJson('/api/v1/vehicle-sizes')->assertOk()->assertJsonPath('data.0.name', 'Sedan');
        $this->getJson('/api/v1/service-categories')->assertOk()->assertJsonPath('data.0.name', 'Wash');
    }

    public function test_owner_adds_sizes_and_categories_at_the_end_of_their_lists(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/vehicle-sizes', ['name' => 'Sedan'])->assertCreated()->assertJsonPath('data.sort_order', 0);
        $this->postJson('/api/v1/vehicle-sizes', ['name' => 'SUV'])->assertCreated()->assertJsonPath('data.sort_order', 1);
        $this->postJson('/api/v1/service-categories', ['name' => 'Wash'])
            ->assertCreated()
            ->assertJsonPath('data.services_count', 0);
        $this->assertDatabaseHas('activity_log', ['event' => 'vehicle_size.created', 'tenant_id' => $this->tenant->id]);
    }

    public function test_names_are_unique_within_the_car_wash(): void
    {
        $this->enterTenant($this->tenant);
        VehicleSize::factory()->create(['name' => 'Sedan']);
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/vehicle-sizes', ['name' => 'Sedan'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('name');
    }

    public function test_staff_without_services_permission_cannot_change_the_catalog(): void
    {
        $this->enterTenant($this->tenant);
        $size = VehicleSize::factory()->create();
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, allBranches: true));

        $this->postJson('/api/v1/vehicle-sizes', ['name' => 'Bus'])->assertForbidden();
        $this->patchJson("/api/v1/vehicle-sizes/{$size->id}", ['name' => 'Renamed'])->assertForbidden();
        $this->deleteJson("/api/v1/vehicle-sizes/{$size->id}")->assertForbidden();
        $this->postJson('/api/v1/service-categories', ['name' => 'Wash'])->assertForbidden();
    }

    public function test_deleting_a_size_removes_its_prices_but_never_the_last_size(): void
    {
        $this->enterTenant($this->tenant);
        $sedan = VehicleSize::factory()->create();
        $suv = VehicleSize::factory()->create();
        $price = ServicePrice::factory()->for(Service::factory())->create(['vehicle_size_id' => $suv->id]);
        Sanctum::actingAs($this->owner);

        $this->deleteJson("/api/v1/vehicle-sizes/{$suv->id}")->assertNoContent();
        $this->assertModelMissing($price);

        $this->deleteJson("/api/v1/vehicle-sizes/{$sedan->id}")
            ->assertUnprocessable()
            ->assertJsonValidationErrors('vehicle_size');
    }

    public function test_deleting_a_category_keeps_its_services_uncategorised(): void
    {
        $this->enterTenant($this->tenant);
        $category = ServiceCategory::factory()->create();
        $service = Service::factory()->create(['service_category_id' => $category->id]);
        Sanctum::actingAs($this->owner);

        $this->deleteJson("/api/v1/service-categories/{$category->id}")->assertNoContent();

        $this->assertNull($service->fresh()->service_category_id);
    }

    public function test_entries_of_another_car_wash_are_not_found(): void
    {
        $foreignSize = VehicleSize::factory()->for(Tenant::factory())->create();
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/vehicle-sizes/{$foreignSize->id}", ['name' => 'Hijacked'])->assertNotFound();
        $this->deleteJson("/api/v1/vehicle-sizes/{$foreignSize->id}")->assertNotFound();
    }
}
