<?php

namespace Tests\Feature;

use App\Domain\Crm\Models\Vehicle;
use App\Domain\Identity\Enums\DefaultRole;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class MembershipTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->tenant->forceFill(['memberships_enabled' => true])->save();
    }

    /**
     * Three washes for 5.000, for 30 days, for any of the customer's cars, unless told otherwise.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function plan(array $overrides = []): string
    {
        Sanctum::actingAs($this->owner);

        return $this->postJson('/api/v1/membership-plans', [
            'name' => '3 washes',
            'price' => 5000,
            'washes' => 3,
            'validity_days' => 30,
            'scope' => 'customer',
            'service_ids' => [$this->wash->id],
            ...$overrides,
        ])->assertCreated()->json('data.id');
    }

    /**
     * The cashier sells the plan on an open shift.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function sell(string $planId, array $overrides = []): TestResponse
    {
        Sanctum::actingAs($this->cashier);
        $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 10000]);

        return $this->postJson("/api/v1/customers/{$this->customer->id}/memberships", [
            'membership_plan_id' => $planId,
            'branch_id' => $this->branch->id,
            'method' => 'cash',
            ...$overrides,
        ]);
    }

    public function test_selling_issues_an_invoice_with_vat_and_puts_the_cash_in_the_drawer(): void
    {
        $this->sell($this->plan())
            ->assertCreated()
            ->assertJsonPath('data.washes_left', 3)
            ->assertJsonPath('data.is_usable', true);

        $this->assertDatabaseHas('invoices', ['total' => 5000, 'vat_amount' => 455, 'order_id' => null, 'customer_id' => $this->customer->id]);
        $this->assertDatabaseHas('invoice_lines', ['name' => '3 washes', 'line_total' => 5000]);
        $this->getJson("/api/v1/shifts/current?branch_id={$this->branch->id}")
            ->assertJsonPath('data.cash_taken', 5000)
            ->assertJsonPath('data.expected_cash', 15000);

        Sanctum::actingAs($this->owner);
        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonPath('data.totals.sales', 5000)
            ->assertJsonPath('data.totals.memberships_sold', 5000)
            ->assertJsonPath('data.by_service.0.name', '3 washes');
        $this->getJson("/api/v1/reports/profit-loss?branch_id={$this->branch->id}")->assertOk();
    }

    public function test_a_wash_from_a_membership_is_free_and_only_add_ons_are_paid(): void
    {
        $membershipId = $this->sell($this->plan())->json('data.id');
        $orderId = $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])->json('data.id');

        $this->pay($orderId, extra: ['membership_id' => $membershipId])
            ->assertCreated()
            ->assertJsonPath('data.invoice.subtotal', 2500)
            ->assertJsonPath('data.invoice.discount_total', 2000)
            ->assertJsonPath('data.invoice.total', 500);

        $this->getJson("/api/v1/customers/{$this->customer->id}/memberships")
            ->assertOk()
            ->assertJsonPath('data.0.washes_left', 2);
    }

    public function test_a_membership_runs_out_and_an_unlimited_one_does_not(): void
    {
        $oneWash = $this->sell($this->plan(['washes' => 1]))->json('data.id');
        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $oneWash])->assertCreated();
        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $oneWash])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('membership');

        $unlimited = $this->sell($this->plan(['name' => 'Monthly', 'washes' => null]))->assertJsonPath('data.washes_left', null)->json('data.id');
        foreach (range(1, 3) as $wash) {
            $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $unlimited])->assertCreated();
        }
    }

    public function test_a_membership_ends_on_its_last_day(): void
    {
        $this->travelTo(CarbonImmutable::parse('2026-11-01 10:00', 'Asia/Bahrain'));
        $membershipId = $this->sell($this->plan(['validity_days' => 10]))->json('data.id');

        $this->travelTo(CarbonImmutable::parse('2026-11-11 23:00', 'Asia/Bahrain'));
        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $membershipId])->assertCreated();

        $this->travelTo(CarbonImmutable::parse('2026-11-12 00:30', 'Asia/Bahrain'));
        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $membershipId])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('membership');
    }

    public function test_a_car_membership_covers_only_that_car(): void
    {
        $planId = $this->plan(['scope' => 'vehicle']);
        $this->sell($planId)->assertUnprocessable()->assertJsonValidationErrors('vehicle_id');
        $membershipId = $this->sell($planId, ['vehicle_id' => $this->vehicle->id])->assertCreated()->json('data.id');

        $otherCar = $this->inTenant(fn () => Vehicle::factory()->for($this->customer)->create(['plate_number' => '54321', 'vehicle_size_id' => $this->sedan->id]));
        $this->pay($this->checkIn(['vehicle_id' => $otherCar->id])->json('data.id'), extra: ['membership_id' => $membershipId])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('membership');

        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $membershipId])->assertCreated();
    }

    public function test_a_membership_covers_only_its_services_and_its_own_customer_without_other_discounts(): void
    {
        $membershipId = $this->sell($this->plan(['service_ids' => [$this->freshener->id]]))->json('data.id');
        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $membershipId])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('membership');

        $walkIn = $this->checkIn(['vehicle_id' => null, 'plate_number' => '77-111', 'vehicle_size_id' => $this->sedan->id])->json('data.id');
        $this->pay($walkIn, extra: ['membership_id' => $membershipId])->assertUnprocessable()->assertJsonValidationErrors('membership');

        $covering = $this->sell($this->plan(['name' => 'Other']))->json('data.id');
        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $covering, 'discount_percent_bps' => 1000, 'discount_reason' => 'x'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('membership');
    }

    public function test_changing_a_plan_leaves_what_was_sold_as_it_was(): void
    {
        $planId = $this->plan();
        $this->sell($planId)->assertCreated();

        Sanctum::actingAs($this->owner);
        $this->patchJson("/api/v1/membership-plans/{$planId}", ['washes' => 1, 'is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->getJson("/api/v1/customers/{$this->customer->id}/memberships")->assertJsonPath('data.0.washes_left', 3);
        $this->sell($planId)->assertUnprocessable()->assertJsonValidationErrors('membership_plan_id');
    }

    public function test_points_are_earned_when_buying_not_on_the_free_wash(): void
    {
        $this->tenant->forceFill(['points_enabled' => true, 'points_earn_amount' => 1000])->save();
        $membershipId = $this->sell($this->plan())->json('data.id');
        $this->assertSame(5, $this->customer->fresh()->points_balance);

        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $membershipId])
            ->assertCreated()
            ->assertJsonPath('data.invoice.total', 0)
            ->assertJsonPath('data.invoice.points_earned', 0);
        $this->assertSame(5, $this->customer->fresh()->points_balance);
    }

    public function test_a_wash_from_a_membership_pays_a_percentage_commission_on_the_regular_price(): void
    {
        Sanctum::actingAs($this->owner);
        $this->putJson("/api/v1/employees/{$this->washer->id}/pay-terms", ['monthly_salary' => 0, 'commission_type' => 'percent', 'commission_value' => 1000])->assertOk();
        $membershipId = $this->sell($this->plan())->json('data.id');

        $orderId = $this->checkIn(['staff_ids' => [$this->washer->id]])->json('data.id');
        $this->pay($orderId, extra: ['membership_id' => $membershipId])->assertCreated();
        $this->washAndPass($orderId, $this->washer);
        $this->moveTo($orderId, 'delivered', $this->cashier)->assertOk();

        Sanctum::actingAs($this->owner);
        $now = now($this->tenant->timezone);
        $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])
            ->assertJsonPath('data.lines.0.commission', 200);
    }

    public function test_only_the_right_staff_set_sell_and_stop_memberships(): void
    {
        Sanctum::actingAs($this->cashier);
        $this->postJson('/api/v1/membership-plans', ['name' => 'x', 'price' => 1, 'validity_days' => 1, 'scope' => 'customer', 'service_ids' => [$this->wash->id]])->assertForbidden();

        $planId = $this->plan();
        Sanctum::actingAs($this->washer);
        $this->postJson("/api/v1/customers/{$this->customer->id}/memberships", ['membership_plan_id' => $planId, 'branch_id' => $this->branch->id, 'method' => 'cash'])->assertForbidden();

        $membershipId = $this->sell($planId)->json('data.id');
        $this->postJson("/api/v1/customer-memberships/{$membershipId}/cancel")->assertForbidden();

        Sanctum::actingAs($this->owner);
        $this->postJson("/api/v1/customer-memberships/{$membershipId}/cancel")->assertOk()->assertJsonPath('data.is_usable', false);
        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $membershipId])->assertUnprocessable();
    }

    public function test_turning_memberships_off_stops_selling_and_using_and_keeps_them(): void
    {
        $planId = $this->plan();
        $membershipId = $this->sell($planId)->json('data.id');

        Sanctum::actingAs($this->owner);
        $this->patchJson('/api/v1/settings', ['memberships_enabled' => false])->assertOk()->assertJsonPath('data.memberships_enabled', false);
        $this->cashier->unsetRelation('tenant');

        $this->sell($planId)->assertUnprocessable()->assertJsonValidationErrors('membership');
        $this->pay($this->checkIn()->json('data.id'), extra: ['membership_id' => $membershipId])->assertUnprocessable()->assertJsonValidationErrors('membership');
        $this->getJson("/api/v1/customers/{$this->customer->id}/memberships")->assertJsonPath('data.0.washes_left', 3);
    }
}
