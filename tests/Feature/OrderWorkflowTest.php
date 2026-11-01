<?php

namespace Tests\Feature;

use App\Domain\Crm\Models\Vehicle;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Orders\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class OrderWorkflowTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $manager;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
    }

    public function test_a_washer_moves_the_car_through_the_queue_and_each_step_is_stamped(): void
    {
        $orderId = $this->checkIn(['bay_id' => $this->bay->id])->json('data.id');

        $this->moveTo($orderId, 'in_progress', $this->washer)->assertOk()->assertJsonPath('data.status', 'in_progress');
        $this->moveTo($orderId, 'qc', $this->washer)->assertOk();
        $response = $this->passInspection($orderId, $this->washer)->assertOk();

        $response->assertJsonPath('data.allowed_next', ['in_progress'])
            ->assertJsonCount(4, 'data.history')
            ->assertJsonPath('data.history.3.by', $this->washer->name);
        $this->assertNotNull($response->json('data.started_at'));
        $this->assertNotNull($response->json('data.qc_at'));
        $this->assertNotNull($response->json('data.ready_at'));
    }

    public function test_skipping_steps_that_are_not_allowed_is_refused(): void
    {
        $orderId = $this->checkIn()->json('data.id');

        $this->moveTo($orderId, 'ready', $this->washer)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['status' => 'An order cannot move from Waiting to Ready.']);
    }

    public function test_delivery_closes_the_order_and_counts_as_the_customers_visit(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        $this->pay($orderId)->assertCreated();
        $this->washAndPass($orderId, $this->cashier);
        $this->moveTo($orderId, 'delivered', $this->cashier)->assertOk();

        $this->getJson("/api/v1/orders/{$orderId}")->assertJsonPath('data.allowed_next', []);
        $this->assertNotNull($this->customer->fresh()->last_visit_at);
        $this->moveTo($orderId, 'in_progress', $this->cashier)->assertUnprocessable();
    }

    public function test_cancelling_needs_the_cancel_permission_and_a_reason(): void
    {
        $orderId = $this->checkIn()->json('data.id');

        $this->moveTo($orderId, 'cancelled', $this->washer, ['reason' => 'Left'])->assertForbidden();
        $this->moveTo($orderId, 'cancelled', $this->manager)->assertUnprocessable()->assertJsonValidationErrors('reason');
        $this->moveTo($orderId, 'cancelled', $this->manager, ['reason' => 'Customer left'])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.cancel_reason', 'Customer left');
    }

    public function test_a_bay_holds_one_car_at_a_time(): void
    {
        $firstId = $this->checkIn(['bay_id' => $this->bay->id])->json('data.id');
        $secondCar = $this->inTenant(fn () => Vehicle::factory()->for($this->customer)->create(['vehicle_size_id' => $this->sedan->id]));
        $secondId = $this->checkIn(['bay_id' => $this->bay->id, 'vehicle_id' => $secondCar->id])->json('data.id');

        $this->moveTo($firstId, 'in_progress', $this->washer)->assertOk();
        $this->moveTo($secondId, 'in_progress', $this->washer)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['bay_id' => 'This bay is busy with another car.']);

        $this->moveTo($firstId, 'qc', $this->washer)->assertOk();
        $this->passInspection($firstId, $this->washer)->assertOk();
        $this->moveTo($secondId, 'in_progress', $this->washer)->assertOk();
    }

    public function test_services_are_re_priced_when_changed_but_not_after_the_car_is_ready(): void
    {
        $orderId = $this->checkIn()->json('data.id');

        $this->patchJson("/api/v1/orders/{$orderId}", ['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])
            ->assertOk()
            ->assertJsonPath('data.subtotal', 2500)
            ->assertJsonCount(2, 'data.items');

        $this->washAndPass($orderId, $this->cashier);

        Sanctum::actingAs($this->cashier);
        $this->patchJson("/api/v1/orders/{$orderId}", ['items' => [['service_id' => $this->wash->id]]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items');
    }

    public function test_bay_staff_and_notes_are_changed_while_the_car_is_in_the_queue(): void
    {
        $orderId = $this->checkIn()->json('data.id');

        $this->patchJson("/api/v1/orders/{$orderId}", ['bay_id' => $this->bay->id, 'staff_ids' => [$this->washer->id], 'notes' => 'Scratch on the left door'])
            ->assertOk()
            ->assertJsonPath('data.bay.id', $this->bay->id)
            ->assertJsonPath('data.staff.0.id', $this->washer->id)
            ->assertJsonPath('data.notes', 'Scratch on the left door');

        Sanctum::actingAs($this->washer);
        $this->patchJson("/api/v1/orders/{$orderId}", ['notes' => 'x'])->assertForbidden();
    }

    public function test_records_with_orders_can_no_longer_be_deleted(): void
    {
        $this->checkIn()->assertCreated();
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Owner));

        $this->deleteJson("/api/v1/customers/{$this->customer->id}")->assertUnprocessable()->assertJsonValidationErrors('customer');
        $this->deleteJson("/api/v1/vehicles/{$this->vehicle->id}")->assertUnprocessable()->assertJsonValidationErrors('vehicle');
        $this->deleteJson("/api/v1/services/{$this->wash->id}")->assertUnprocessable()->assertJsonValidationErrors('service');
        $this->assertSame(1, $this->inTenant(fn () => Order::query()->count()));
    }
}
