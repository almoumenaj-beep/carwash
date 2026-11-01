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

class CustomerApiTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private User $cashier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->cashier = $this->createStaff($this->tenant, DefaultRole::Cashier);
    }

    public function test_cashier_registers_a_customer_with_their_car_in_one_step(): void
    {
        $size = $this->inTenant(fn () => VehicleSize::factory()->create());
        Sanctum::actingAs($this->cashier);

        $response = $this->postJson('/api/v1/customers', [
            'phone' => '3333 4444',
            'name' => 'Ahmed',
            'marketing_consent' => true,
            'vehicles' => [['plate_number' => '12 345', 'vehicle_size_id' => $size->id, 'make' => 'Toyota']],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.phone', '+97333334444')
            ->assertJsonPath('data.marketing_consent', true)
            ->assertJsonPath('data.vehicles.0.plate_number', '12345')
            ->assertJsonPath('data.vehicles.0.vehicle_size_id', $size->id);
        $this->assertNotNull($response->json('data.marketing_consent_at'));
        $this->assertDatabaseHas('activity_log', ['event' => 'customer.created', 'subject_id' => $response->json('data.id')]);
    }

    public function test_the_same_phone_typed_differently_is_the_same_customer(): void
    {
        $this->inTenant(fn () => Customer::factory()->create(['phone' => '+97333334444']));
        Sanctum::actingAs($this->cashier);

        $this->postJson('/api/v1/customers', ['phone' => '٣٣٣٣ ٤٤٤٤'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['phone' => 'A customer with this phone number already exists.']);
    }

    public function test_a_plate_belongs_to_only_one_customer(): void
    {
        $this->inTenant(fn () => Vehicle::factory()->for(Customer::factory())->create(['plate_number' => '12345']));
        Sanctum::actingAs($this->cashier);

        $this->postJson('/api/v1/customers', ['phone' => '35556666', 'vehicles' => [['plate_number' => '12-345']]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['vehicles.0.plate_number' => 'This plate is already registered to another customer.']);
        $this->assertDatabaseMissing('customers', ['phone' => '+97335556666']);
    }

    public function test_search_finds_customers_by_name_phone_or_plate(): void
    {
        $this->inTenant(function (): void {
            $ahmed = Customer::factory()->create(['name' => 'Ahmed Ali', 'phone' => '+97333334444']);
            Vehicle::factory()->for($ahmed)->create(['plate_number' => '55501']);
            Customer::factory()->create(['name' => 'Sara', 'phone' => '+97339990000']);
        });
        Sanctum::actingAs($this->cashier);

        foreach (['ahmed', '3333', '555', '5 55 01'] as $term) {
            $this->getJson('/api/v1/customers?search='.urlencode($term))
                ->assertOk()
                ->assertJsonCount(1, 'data')
                ->assertJsonPath('data.0.name', 'Ahmed Ali');
        }
        $this->getJson('/api/v1/customers')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_customers_of_another_car_wash_are_never_listed_or_found(): void
    {
        $foreign = Customer::factory()->for(Tenant::factory())->create(['name' => 'Outsider']);
        Sanctum::actingAs($this->cashier);

        $this->getJson('/api/v1/customers?search=Outsider')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson("/api/v1/customers/{$foreign->id}")->assertNotFound();
        $this->patchJson("/api/v1/customers/{$foreign->id}", ['name' => 'Hijacked'])->assertNotFound();
    }

    public function test_withdrawing_marketing_consent_clears_its_date(): void
    {
        $customer = $this->inTenant(fn () => Customer::factory()->consenting()->create());
        Sanctum::actingAs($this->cashier);

        $this->patchJson("/api/v1/customers/{$customer->id}", ['marketing_consent' => false, 'phone' => '+973 3777 1111'])
            ->assertOk()
            ->assertJsonPath('data.marketing_consent', false)
            ->assertJsonPath('data.marketing_consent_at', null)
            ->assertJsonPath('data.phone', '+97337771111');
    }

    public function test_washers_cannot_see_customers_and_cashiers_cannot_delete_them(): void
    {
        $customer = $this->inTenant(fn () => Customer::factory()->create());

        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Washer));
        $this->getJson('/api/v1/customers')->assertForbidden();

        Sanctum::actingAs($this->cashier);
        $this->deleteJson("/api/v1/customers/{$customer->id}")->assertForbidden();
    }

    public function test_owner_deletes_a_customer_with_their_cars(): void
    {
        [$customer, $vehicle] = $this->inTenant(function (): array {
            $customer = Customer::factory()->create();

            return [$customer, Vehicle::factory()->for($customer)->create()];
        });
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Owner));

        $this->deleteJson("/api/v1/customers/{$customer->id}")->assertNoContent();

        $this->assertModelMissing($customer);
        $this->assertModelMissing($vehicle);
    }

    /**
     * @template TReturn
     *
     * @param  callable(): TReturn  $callback
     * @return TReturn
     */
    private function inTenant(callable $callback): mixed
    {
        return $this->app->make(TenantContext::class)->run($this->tenant, $callback);
    }
}
