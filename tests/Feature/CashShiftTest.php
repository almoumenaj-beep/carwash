<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class CashShiftTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
    }

    private function openShift(int $float = 10000): string
    {
        Sanctum::actingAs($this->cashier);

        return $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => $float])
            ->assertCreated()
            ->json('data.id');
    }

    public function test_cash_cannot_be_taken_without_an_open_shift(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        Sanctum::actingAs($this->cashier);

        $this->postJson("/api/v1/orders/{$orderId}/checkout")
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['shift' => 'Open your shift before taking payment.']);
    }

    public function test_card_and_benefit_payments_stay_out_of_the_drawer(): void
    {
        $shiftId = $this->openShift();

        $this->pay($this->checkIn()->json('data.id'), extra: ['method' => 'card'])->assertCreated();
        $this->pay($this->checkIn()->json('data.id'), extra: ['method' => 'benefit'])->assertCreated();
        $this->pay($this->checkIn()->json('data.id'), extra: ['tendered' => 2000])->assertCreated();

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/shifts/current?branch_id={$this->branch->id}")
            ->assertJsonPath('data.invoices_count', 3)
            ->assertJsonPath('data.cash_taken', 2000)
            ->assertJsonPath('data.card_taken', 2000)
            ->assertJsonPath('data.benefit_taken', 2000)
            ->assertJsonPath('data.expected_cash', 12000);

        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 12000])
            ->assertOk()
            ->assertJsonPath('data.variance', 0);
    }

    public function test_a_cashier_opens_one_shift_per_branch_and_sees_it_live(): void
    {
        $shiftId = $this->openShift();

        $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 0])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('shift');

        $this->pay($this->checkIn()->json('data.id'), extra: ['tendered' => 5000])->assertCreated();

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/shifts/current?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $shiftId)
            ->assertJsonPath('data.is_open', true)
            ->assertJsonPath('data.opening_float', 10000)
            ->assertJsonPath('data.invoices_count', 1)
            ->assertJsonPath('data.cash_taken', 2000)
            ->assertJsonPath('data.expected_cash', 12000);
    }

    public function test_closing_counts_the_drawer_and_records_the_variance(): void
    {
        $shiftId = $this->openShift();
        $this->pay($this->checkIn()->json('data.id'))->assertCreated();
        $this->pay($this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])->json('data.id'))
            ->assertCreated();

        Sanctum::actingAs($this->cashier);
        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 14000])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['note' => 'The drawer does not match; explain the difference.']);

        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 14000, 'note' => 'Gave 0.500 too much change'])
            ->assertOk()
            ->assertJsonPath('data.is_open', false)
            ->assertJsonPath('data.cash_taken', 4500)
            ->assertJsonPath('data.expected_cash', 14500)
            ->assertJsonPath('data.counted_cash', 14000)
            ->assertJsonPath('data.variance', -500)
            ->assertJsonPath('data.closed_by.id', $this->cashier->id);

        $this->getJson("/api/v1/shifts/current?branch_id={$this->branch->id}")->assertJsonPath('data', null);
        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 14500])->assertUnprocessable();
        $this->assertDatabaseHas('activity_log', ['event' => 'cash_shift.closed', 'subject_id' => $shiftId]);
    }

    public function test_a_matching_drawer_closes_without_a_note(): void
    {
        $shiftId = $this->openShift(5000);

        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 5000])
            ->assertOk()
            ->assertJsonPath('data.variance', 0);
    }

    public function test_only_till_staff_open_shifts_and_only_their_own_are_closed(): void
    {
        Sanctum::actingAs($this->washer);
        $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 0])->assertForbidden();

        $otherCashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->otherBranch]);
        Sanctum::actingAs($otherCashier);
        $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 0])->assertForbidden();

        $shiftId = $this->openShift();
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
        Sanctum::actingAs($manager);
        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 10000])->assertForbidden();
    }

    public function test_managers_see_every_shift_of_the_branch_and_cashiers_only_their_own(): void
    {
        $this->openShift();
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        Sanctum::actingAs($owner);
        $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 0])->assertCreated();

        $this->getJson("/api/v1/shifts?branch_id={$this->branch->id}")->assertOk()->assertJsonCount(2, 'data');

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/shifts?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.opened_by.id', $this->cashier->id);
    }
}
