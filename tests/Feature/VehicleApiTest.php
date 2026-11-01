<?php

namespace Tests\Feature;

use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class VehicleApiTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private User $cashier;

    private Customer $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->cashier = $this->createStaff($this->tenant, DefaultRole::Cashier);
        $this->customer = $this->app->make(TenantContext::class)->run($this->tenant, fn () => Customer::factory()->create());
    }

    public function test_cashier_adds_a_car_to_a_customer(): void
    {
        Sanctum::actingAs($this->cashier);

        $this->postJson("/api/v1/customers/{$this->customer->id}/vehicles", ['plate_number' => 'ab 77 01', 'color' => 'White'])
            ->assertCreated()
            ->assertJsonPath('data.plate_number', 'AB7701')
            ->assertJsonPath('data.customer_id', $this->customer->id);
    }

    public function test_a_car_is_transferred_to_its_new_owner(): void
    {
        [$vehicle, $buyer] = $this->app->make(TenantContext::class)->run($this->tenant, fn () => [
            Vehicle::factory()->for($this->customer)->create(),
            Customer::factory()->create(),
        ]);
        Sanctum::actingAs($this->cashier);

        $this->patchJson("/api/v1/vehicles/{$vehicle->id}", ['customer_id' => $buyer->id])
            ->assertOk()
            ->assertJsonPath('data.customer_id', $buyer->id);
        $this->assertDatabaseHas('activity_log', ['event' => 'vehicle.updated', 'subject_id' => $vehicle->id]);
    }

    public function test_cars_cannot_be_moved_to_or_sized_from_another_car_wash(): void
    {
        $vehicle = $this->app->make(TenantContext::class)->run($this->tenant, fn () => Vehicle::factory()->for($this->customer)->create());
        $foreignCustomer = Customer::factory()->for(Tenant::factory())->create();
        $foreignSize = VehicleSize::factory()->for(Tenant::factory())->create();
        Sanctum::actingAs($this->cashier);

        $this->patchJson("/api/v1/vehicles/{$vehicle->id}", ['customer_id' => $foreignCustomer->id, 'vehicle_size_id' => $foreignSize->id])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['customer_id', 'vehicle_size_id']);
    }

    public function test_a_plate_already_registered_is_refused(): void
    {
        $this->app->make(TenantContext::class)->run($this->tenant, fn () => Vehicle::factory()->for($this->customer)->create(['plate_number' => '12345']));
        Sanctum::actingAs($this->cashier);

        $this->postJson("/api/v1/customers/{$this->customer->id}/vehicles", ['plate_number' => '12 345'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('plate_number');
    }

    public function test_only_staff_allowed_to_delete_remove_a_car(): void
    {
        $vehicle = $this->app->make(TenantContext::class)->run($this->tenant, fn () => Vehicle::factory()->for($this->customer)->create());

        Sanctum::actingAs($this->cashier);
        $this->deleteJson("/api/v1/vehicles/{$vehicle->id}")->assertForbidden();

        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Owner));
        $this->deleteJson("/api/v1/vehicles/{$vehicle->id}")->assertNoContent();
        $this->assertModelMissing($vehicle);
    }

    public function test_cars_of_another_car_wash_are_not_found(): void
    {
        $foreignVehicle = Vehicle::factory()->for(Customer::factory()->for(Tenant::factory()))->create();
        Sanctum::actingAs($this->cashier);

        $this->patchJson("/api/v1/vehicles/{$foreignVehicle->id}", ['color' => 'Pink'])->assertNotFound();
        $this->postJson("/api/v1/customers/{$foreignVehicle->customer_id}/vehicles", ['plate_number' => '999'])->assertNotFound();
    }
}
