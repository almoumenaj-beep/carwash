<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class PointsTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        // A point per 1.000 spent; 10 points are worth 2.000.
        $this->tenant->forceFill([
            'points_enabled' => true,
            'points_earn_amount' => 1000,
            'points_redeem_points' => 10,
            'points_redeem_value' => 2000,
        ])->save();
    }

    private function givePoints(int $points): void
    {
        $this->customer->forceFill(['points_balance' => $points])->save();
    }

    private function balance(): int
    {
        return $this->customer->fresh()->points_balance;
    }

    public function test_a_paid_invoice_earns_points_on_what_was_paid_rounded_down(): void
    {
        // A wash and a freshener: 2.500 earns 2 points, with 0.500 too little for a third.
        $orderId = $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])->json('data.id');

        $this->pay($orderId, extra: ['method' => 'benefit'])
            ->assertCreated()
            ->assertJsonPath('data.invoice.points_earned', 2)
            ->assertJsonPath('data.customer.points_balance', 2);

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/customers/{$this->customer->id}/points")
            ->assertOk()
            ->assertJsonPath('balance', 2)
            ->assertJsonPath('data.0.type', 'earned')
            ->assertJsonPath('data.0.points', 2)
            ->assertJsonPath('data.0.invoice_reference', 'MAIN-INV-1');
    }

    public function test_points_are_earned_after_a_discount_and_never_without_a_customer(): void
    {
        $this->pay($this->checkIn()->json('data.id'), extra: ['discount_percent_bps' => 1000, 'discount_reason' => 'Regular'])
            ->assertCreated()
            ->assertJsonPath('data.invoice.points_earned', 1);

        $this->pay($this->checkIn(['vehicle_id' => null, 'plate_number' => '77-111', 'vehicle_size_id' => $this->sedan->id])->json('data.id'))
            ->assertCreated()
            ->assertJsonPath('data.invoice.points_earned', 0);

        $this->assertSame(1, $this->balance());
    }

    public function test_redeeming_takes_money_off_and_only_the_rest_earns_points(): void
    {
        $this->givePoints(25);
        $orderId = $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])->json('data.id');

        // 10 points take 2.000 off 2.500; the 0.500 left earns nothing, and 15 points remain.
        $this->pay($orderId, extra: ['redeem_points' => 10])
            ->assertCreated()
            ->assertJsonPath('data.invoice.discount_total', 2000)
            ->assertJsonPath('data.invoice.total', 500)
            ->assertJsonPath('data.invoice.vat_amount', 45)
            ->assertJsonPath('data.invoice.points_redeemed', 10)
            ->assertJsonPath('data.invoice.points_earned', 0)
            ->assertJsonPath('data.customer.points_balance', 15);

        $this->getJson("/api/v1/customers/{$this->customer->id}/points")
            ->assertJsonPath('data.0.type', 'redeemed')
            ->assertJsonPath('data.0.points', -10);
    }

    public function test_a_visit_paid_entirely_with_points_issues_an_invoice_and_leaves_the_drawer_alone(): void
    {
        $this->givePoints(10);

        $this->pay($this->checkIn()->json('data.id'), extra: ['redeem_points' => 10])
            ->assertCreated()
            ->assertJsonPath('data.is_paid', true)
            ->assertJsonPath('data.invoice.total', 0);

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/shifts/current?branch_id={$this->branch->id}")->assertJsonPath('data.expected_cash', 0);
    }

    public function test_redeeming_is_refused_and_nothing_recorded_when_it_breaks_a_rule(): void
    {
        $this->givePoints(15);
        $orderId = $this->checkIn()->json('data.id');

        foreach ([
            'not enough points' => ['redeem_points' => 20],
            'not a whole step' => ['redeem_points' => 5],
            'joined with a discount' => ['redeem_points' => 10, 'discount_percent_bps' => 1000, 'discount_reason' => 'Regular'],
        ] as $case => $extra) {
            $this->pay($orderId, extra: $extra)->assertUnprocessable()->assertJsonValidationErrors('points');
        }

        $this->givePoints(100);
        $this->pay($orderId, extra: ['redeem_points' => 20])->assertUnprocessable()->assertJsonValidationErrors('points');

        $this->assertDatabaseCount('invoices', 0);
        $this->assertSame(100, $this->balance());
    }

    public function test_a_customer_needs_no_discount_permission_to_redeem(): void
    {
        $this->givePoints(10);
        $this->inTenant(fn () => $this->cashier->roles->each->update(['max_discount_bps' => 0]));

        $this->pay($this->checkIn()->json('data.id'), extra: ['redeem_points' => 10])->assertCreated();
    }

    public function test_the_owner_sets_the_rules_and_turning_points_off_keeps_the_balance(): void
    {
        $this->givePoints(10);

        Sanctum::actingAs($this->cashier);
        $this->patchJson('/api/v1/settings', ['points_enabled' => false])->assertForbidden();

        Sanctum::actingAs($this->owner);
        $this->patchJson('/api/v1/settings', ['points_earn_amount' => 500, 'points_redeem_points' => 50, 'points_redeem_value' => 1000, 'points_expiry_months' => 6])
            ->assertOk()
            ->assertJsonPath('data.points_earn_amount', 500)
            ->assertJsonPath('data.points_redeem_points', 50)
            ->assertJsonPath('data.points_redeem_value', 1000)
            ->assertJsonPath('data.points_expiry_months', 6);
        $this->patchJson('/api/v1/settings', ['points_redeem_points' => 0])->assertUnprocessable()->assertJsonValidationErrors('points_redeem_points');

        $this->patchJson('/api/v1/settings', ['points_enabled' => false])->assertOk()->assertJsonPath('data.points_enabled', false);
        $this->pay($this->checkIn()->json('data.id'), $this->owner, ['redeem_points' => 10])->assertUnprocessable()->assertJsonValidationErrors('points');
        $this->pay($this->checkIn()->json('data.id'), $this->owner)->assertCreated()->assertJsonPath('data.invoice.points_earned', 0);
        $this->assertSame(10, $this->balance());
    }

    public function test_points_expire_after_the_owners_period_without_activity(): void
    {
        $this->tenant->forceFill(['points_expiry_months' => 6])->save();
        $this->travelTo(CarbonImmutable::parse('2026-01-10 10:00', 'Asia/Bahrain'));
        $this->pay($this->checkIn()->json('data.id'))->assertCreated();
        $this->assertSame(2, $this->balance());

        $this->travelTo(CarbonImmutable::parse('2026-07-01 10:00', 'Asia/Bahrain'));
        $this->artisan('points:expire')->assertSuccessful();
        $this->assertSame(2, $this->balance(), 'still inside the six months');

        $this->travelTo(CarbonImmutable::parse('2026-07-11 10:00', 'Asia/Bahrain'));
        $this->artisan('points:expire')->assertSuccessful();
        $this->assertSame(0, $this->balance());

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/customers/{$this->customer->id}/points")
            ->assertJsonPath('data.0.type', 'expired')
            ->assertJsonPath('data.0.points', -2)
            ->assertJsonPath('data.0.created_by', null);
    }

    public function test_points_never_expire_without_a_period(): void
    {
        $this->givePoints(10);
        $this->travelTo(now()->addYears(5));

        $this->artisan('points:expire')->assertSuccessful();

        $this->assertSame(10, $this->balance());
    }
}
