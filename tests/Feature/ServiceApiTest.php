<?php

namespace Tests\Feature;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServiceCategory;
use App\Domain\Catalog\Models\ServicePrice;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class ServiceApiTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private User $owner;

    private VehicleSize $sedan;

    private VehicleSize $suv;

    private Branch $branch;

    private ServiceCategory $wash;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);

        $this->app->make(TenantContext::class)->run($this->tenant, function (): void {
            $this->sedan = VehicleSize::factory()->create(['name' => 'Sedan']);
            $this->suv = VehicleSize::factory()->create(['name' => 'SUV']);
            $this->branch = Branch::factory()->create();
            $this->wash = ServiceCategory::factory()->create(['name' => 'Wash']);
        });
    }

    public function test_owner_adds_a_service_with_prices_per_size_and_a_branch_price(): void
    {
        Sanctum::actingAs($this->owner);

        $response = $this->postJson('/api/v1/services', [
            'name' => 'Exterior wash',
            'service_category_id' => $this->wash->id,
            'duration_minutes' => 15,
            'prices' => [
                ['vehicle_size_id' => $this->sedan->id, 'price' => 2000],
                ['vehicle_size_id' => $this->suv->id, 'price' => 2500],
                ['vehicle_size_id' => $this->suv->id, 'branch_id' => $this->branch->id, 'price' => 2750],
            ],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.name', 'Exterior wash')
            ->assertJsonPath('data.is_addon', false)
            ->assertJsonCount(3, 'data.prices');

        $service = Service::query()->withoutGlobalScopes()->findOrFail($response->json('data.id'))->load('prices');
        $this->assertSame(2750, $service->priceFor($this->suv, $this->branch));
        $this->assertSame(2000, $service->priceFor($this->sedan, $this->branch));
        $this->assertDatabaseHas('activity_log', ['event' => 'service.created', 'subject_id' => $service->id]);
    }

    public function test_an_addon_can_have_one_price_for_every_size(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/services', ['name' => 'Air freshener', 'is_addon' => true, 'prices' => [['price' => 500]]])
            ->assertCreated()
            ->assertJsonPath('data.is_addon', true)
            ->assertJsonPath('data.prices.0.vehicle_size_id', null)
            ->assertJsonPath('data.prices.0.price', 500);
    }

    public function test_a_size_and_branch_combination_has_only_one_price(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/services', [
            'name' => 'Exterior wash',
            'prices' => [['vehicle_size_id' => $this->sedan->id, 'price' => 2000], ['vehicle_size_id' => $this->sedan->id, 'price' => 1800]],
        ])->assertUnprocessable()->assertJsonValidationErrors('prices');

        $this->assertDatabaseMissing('services', ['name' => 'Exterior wash']);
    }

    public function test_prices_must_be_whole_minor_units_for_sizes_and_branches_of_the_car_wash(): void
    {
        $foreignSize = VehicleSize::factory()->for(Tenant::factory())->create();
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/services', [
            'name' => 'Exterior wash',
            'prices' => [
                ['vehicle_size_id' => $foreignSize->id, 'price' => 2000],
                ['vehicle_size_id' => $this->sedan->id, 'price' => 2.5],
            ],
        ])->assertUnprocessable()->assertJsonValidationErrors(['prices.0.vehicle_size_id', 'prices.1.price']);
    }

    public function test_updating_prices_replaces_the_price_list_and_is_audited(): void
    {
        $service = $this->serviceWithPrice(2000);
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/services/{$service->id}", ['prices' => [['vehicle_size_id' => $this->suv->id, 'price' => 3000]]])
            ->assertOk()
            ->assertJsonCount(1, 'data.prices')
            ->assertJsonPath('data.prices.0.price', 3000);

        $this->assertDatabaseHas('activity_log', ['event' => 'service.updated', 'subject_id' => $service->id]);
    }

    public function test_updating_other_fields_keeps_the_prices(): void
    {
        $service = $this->serviceWithPrice(2000);
        Sanctum::actingAs($this->owner);

        $this->patchJson("/api/v1/services/{$service->id}", ['name' => 'Express wash', 'is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false)
            ->assertJsonPath('data.prices.0.price', 2000);
    }

    public function test_every_staff_member_reads_the_menu_but_only_managers_change_it(): void
    {
        $service = $this->serviceWithPrice(2000);
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Cashier));

        $this->getJson('/api/v1/services')->assertOk()->assertJsonPath('data.0.prices.0.price', 2000);
        $this->getJson("/api/v1/services/{$service->id}")->assertOk();
        $this->postJson('/api/v1/services', ['name' => 'Discount wash'])->assertForbidden();
        $this->patchJson("/api/v1/services/{$service->id}", ['prices' => [['price' => 1]]])->assertForbidden();
    }

    public function test_an_unsold_service_is_deleted_with_its_prices(): void
    {
        $service = $this->serviceWithPrice(2000);
        $priceId = ServicePrice::query()->withoutGlobalScopes()->where('service_id', $service->id)->value('id');
        Sanctum::actingAs($this->owner);

        $this->deleteJson("/api/v1/services/{$service->id}")->assertNoContent();

        $this->assertModelMissing($service);
        $this->assertDatabaseMissing('service_prices', ['id' => $priceId]);
    }

    public function test_services_of_another_car_wash_are_not_found(): void
    {
        $foreignService = Service::factory()->for(Tenant::factory())->create();
        Sanctum::actingAs($this->owner);

        $this->getJson("/api/v1/services/{$foreignService->id}")->assertNotFound();
        $this->patchJson("/api/v1/services/{$foreignService->id}", ['name' => 'Hijacked'])->assertNotFound();
    }

    private function serviceWithPrice(int $price): Service
    {
        return $this->app->make(TenantContext::class)->run($this->tenant, function () use ($price): Service {
            $service = Service::factory()->create();
            ServicePrice::factory()->for($service)->create(['vehicle_size_id' => $this->sedan->id, 'price' => $price]);

            return $service;
        });
    }
}
