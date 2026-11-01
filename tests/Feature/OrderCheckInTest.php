<?php

namespace Tests\Feature;

use App\Domain\Catalog\Models\ServicePrice;
use App\Domain\Crm\Models\Customer;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class OrderCheckInTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
    }

    public function test_a_registered_car_is_checked_in_at_its_size_price(): void
    {
        $response = $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]]);

        $response->assertCreated()
            ->assertJsonPath('data.reference', 'MAIN-1')
            ->assertJsonPath('data.status', 'waiting')
            ->assertJsonPath('data.allowed_next', ['in_progress', 'cancelled'])
            ->assertJsonPath('data.customer.id', $this->customer->id)
            ->assertJsonPath('data.plate_number', '12345')
            ->assertJsonPath('data.vehicle_size_id', $this->sedan->id)
            ->assertJsonPath('data.items.0.unit_price', 2000)
            ->assertJsonPath('data.items.1.unit_price', 500)
            ->assertJsonPath('data.subtotal', 2500)
            ->assertJsonPath('data.estimated_minutes', 17)
            ->assertJsonPath('data.created_by.id', $this->cashier->id);
        $this->assertDatabaseHas('order_status_history', ['order_id' => $response->json('data.id'), 'to_status' => 'waiting']);
    }

    public function test_a_walk_in_plate_of_a_registered_car_is_linked_to_its_owner(): void
    {
        $this->checkIn(['vehicle_id' => null, 'plate_number' => '12-345'])
            ->assertCreated()
            ->assertJsonPath('data.vehicle_id', $this->vehicle->id)
            ->assertJsonPath('data.customer.id', $this->customer->id);
    }

    public function test_an_unknown_walk_in_is_priced_by_the_size_given(): void
    {
        $this->checkIn(['vehicle_id' => null, 'plate_number' => '777', 'vehicle_size_id' => $this->suv->id])
            ->assertCreated()
            ->assertJsonPath('data.customer', null)
            ->assertJsonPath('data.vehicle_id', null)
            ->assertJsonPath('data.subtotal', 2500);
    }

    public function test_a_walk_in_who_gives_a_phone_number_is_registered_with_their_car(): void
    {
        $response = $this->checkIn([
            'vehicle_id' => null,
            'plate_number' => '777',
            'vehicle_size_id' => $this->suv->id,
            'customer_phone' => '3911 2233',
            'customer_name' => 'Hassan',
        ]);

        $response->assertCreated()->assertJsonPath('data.customer.name', 'Hassan');
        $customer = $this->inTenant(fn () => Customer::query()->where('phone', '+97339112233')->sole());
        $this->assertSame($customer->id, $response->json('data.customer.id'));
        $this->assertDatabaseHas('vehicles', [
            'id' => $response->json('data.vehicle_id'),
            'customer_id' => $customer->id,
            'plate_number' => '777',
            'vehicle_size_id' => $this->suv->id,
        ]);
    }

    public function test_a_new_car_of_a_known_phone_number_is_added_to_that_customer(): void
    {
        $this->checkIn([
            'vehicle_id' => null,
            'plate_number' => '888',
            'vehicle_size_id' => $this->sedan->id,
            'customer_phone' => $this->customer->phone,
            'customer_name' => 'Someone else',
        ])->assertCreated()->assertJsonPath('data.customer.id', $this->customer->id);

        $this->assertSame(1, $this->inTenant(fn () => Customer::query()->count()));
        $this->assertSame(2, $this->customer->vehicles()->count());
        $this->assertNotSame('Someone else', $this->customer->fresh()->name);
    }

    public function test_a_registered_plate_keeps_its_owner_even_when_a_phone_is_given(): void
    {
        $this->checkIn(['vehicle_id' => null, 'plate_number' => '12345', 'customer_phone' => '39112233'])
            ->assertCreated()
            ->assertJsonPath('data.customer.id', $this->customer->id);

        $this->assertSame(1, $this->inTenant(fn () => Customer::query()->count()));
    }

    public function test_registering_a_walk_in_needs_the_permission_to_add_customers(): void
    {
        $counter = $this->createStaffWithPermissions($this->tenant, [Permission::OrdersView, Permission::OrdersCreate]);
        $walkIn = ['vehicle_id' => null, 'plate_number' => '777', 'vehicle_size_id' => $this->suv->id];

        $this->checkIn([...$walkIn, 'customer_phone' => '39112233'], $counter)->assertForbidden();
        $this->checkIn($walkIn, $counter)->assertCreated()->assertJsonPath('data.customer', null);
    }

    public function test_an_invalid_walk_in_phone_is_refused(): void
    {
        $this->checkIn(['vehicle_id' => null, 'plate_number' => '777', 'vehicle_size_id' => $this->suv->id, 'customer_phone' => '12'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['customer_phone' => 'Enter a valid phone number.']);
    }

    public function test_a_branch_price_overrides_the_general_price(): void
    {
        $this->inTenant(fn () => ServicePrice::factory()->for($this->wash)->create([
            'vehicle_size_id' => $this->sedan->id,
            'branch_id' => $this->branch->id,
            'price' => 1800,
        ]));

        $this->checkIn()->assertCreated()->assertJsonPath('data.subtotal', 1800);
    }

    public function test_prices_changed_later_do_not_change_the_order(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        $this->inTenant(fn () => ServicePrice::query()->where('service_id', $this->wash->id)->update(['price' => 9999]));

        $this->getJson("/api/v1/orders/{$orderId}")->assertJsonPath('data.subtotal', 2000);
    }

    public function test_add_ons_alone_are_refused(): void
    {
        $this->checkIn(['items' => [['service_id' => $this->freshener->id]]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items' => 'Add at least one main service; add-ons are sold with one.']);
    }

    public function test_a_service_without_a_price_for_the_size_is_refused(): void
    {
        $this->checkIn(['vehicle_id' => null, 'plate_number' => '777', 'vehicle_size_id' => null])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items.0.service_id' => 'Exterior wash has no price for this vehicle size.']);
    }

    public function test_an_inactive_service_cannot_be_sold(): void
    {
        $this->inTenant(fn () => $this->wash->update(['is_active' => false]));

        $this->checkIn()->assertUnprocessable()->assertJsonValidationErrors('items.0.service_id');
    }

    public function test_numbers_count_up_per_branch(): void
    {
        $this->checkIn()->assertJsonPath('data.number', 1);
        $this->checkIn()->assertJsonPath('data.number', 2);

        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->checkIn(['branch_id' => $this->otherBranch->id], $owner)->assertJsonPath('data.reference', 'SEEF-1');
    }

    public function test_bay_and_staff_must_belong_to_the_branch(): void
    {
        $foreignBay = $this->inTenant(fn () => Bay::factory()->for($this->otherBranch)->create());

        $this->checkIn(['bay_id' => $foreignBay->id])->assertUnprocessable()->assertJsonValidationErrors('bay_id');

        $outsider = $this->createStaff($this->tenant, DefaultRole::Washer, [$this->otherBranch]);
        $this->checkIn(['staff_ids' => [$outsider->id]])->assertUnprocessable()->assertJsonValidationErrors('staff_ids');

        $this->checkIn(['bay_id' => $this->bay->id, 'staff_ids' => [$this->washer->id]])
            ->assertCreated()
            ->assertJsonPath('data.bay.name', 'Bay 1')
            ->assertJsonPath('data.staff.0.id', $this->washer->id);
    }

    public function test_staff_check_cars_in_only_at_their_own_branch_and_with_permission(): void
    {
        $this->checkIn(['branch_id' => $this->otherBranch->id])->assertForbidden();
        $this->checkIn([], $this->washer)->assertForbidden();
    }

    public function test_a_branch_of_another_car_wash_is_rejected(): void
    {
        $foreignBranch = Branch::factory()->for(Tenant::factory())->create();

        $this->checkIn(['branch_id' => $foreignBranch->id])->assertUnprocessable()->assertJsonValidationErrors('branch_id');
    }
}
