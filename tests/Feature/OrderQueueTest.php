<?php

namespace Tests\Feature;

use App\Domain\Crm\Models\Vehicle;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Orders\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class OrderQueueTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
    }

    private function newCar(): Vehicle
    {
        return $this->inTenant(fn () => Vehicle::factory()->for($this->customer)->create(['vehicle_size_id' => $this->sedan->id]));
    }

    public function test_the_queue_shows_cars_still_in_the_wash_oldest_first(): void
    {
        $first = $this->checkIn()->json('data.id');
        $second = $this->checkIn(['vehicle_id' => $this->newCar()->id])->json('data.id');
        $delivered = $this->checkIn(['vehicle_id' => $this->newCar()->id])->json('data.id');
        $this->pay($delivered);
        $this->washAndPass($delivered, $this->cashier);
        $this->moveTo($delivered, 'delivered', $this->cashier)->assertOk();

        Sanctum::actingAs($this->washer);
        $this->getJson("/api/v1/orders?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $first)
            ->assertJsonPath('data.1.id', $second);
    }

    public function test_today_lists_everything_checked_in_today_including_finished_cars(): void
    {
        $today = $this->checkIn()->json('data.id');
        $this->moveTo($today, 'cancelled', $this->createStaff($this->tenant, DefaultRole::Owner), ['reason' => 'Test']);
        $yesterday = $this->checkIn(['vehicle_id' => $this->newCar()->id])->json('data.id');
        $this->inTenant(fn () => Order::query()->whereKey($yesterday)->update(['created_at' => now()->subDays(2)]));

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/orders?branch_id={$this->branch->id}&scope=today")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $today);
    }

    public function test_the_queue_of_another_branch_is_off_limits(): void
    {
        Sanctum::actingAs($this->washer);

        $this->getJson("/api/v1/orders?branch_id={$this->otherBranch->id}")->assertForbidden();
        $this->getJson('/api/v1/orders')->assertUnprocessable()->assertJsonValidationErrors('branch_id');
    }

    public function test_orders_and_branches_of_another_car_wash_are_not_found(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        $outsider = $this->createStaff($this->createTenantWithRoles(), DefaultRole::Owner);
        Sanctum::actingAs($outsider);

        $this->getJson("/api/v1/orders/{$orderId}")->assertNotFound();
        $this->postJson("/api/v1/orders/{$orderId}/status", ['status' => 'cancelled', 'reason' => 'x'])->assertNotFound();
        $this->getJson("/api/v1/orders?branch_id={$this->branch->id}")->assertNotFound();
    }

    public function test_an_order_shows_its_history(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        $this->moveTo($orderId, 'in_progress', $this->washer);

        $this->getJson("/api/v1/orders/{$orderId}")
            ->assertOk()
            ->assertJsonPath('data.history.0.to', 'waiting')
            ->assertJsonPath('data.history.1.from', 'waiting')
            ->assertJsonPath('data.history.1.to', 'in_progress');
    }
}
