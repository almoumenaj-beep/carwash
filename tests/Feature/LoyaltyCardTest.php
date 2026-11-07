<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class LoyaltyCardTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->tenant->forceFill(['loyalty_enabled' => true, 'loyalty_washes_required' => 3])->save();
    }

    private function giveStamps(int $stamps): void
    {
        $this->customer->forceFill(['loyalty_stamps' => $stamps])->save();
    }

    private function stamps(): int
    {
        return $this->customer->fresh()->loyalty_stamps;
    }

    public function test_each_paid_visit_of_a_registered_customer_earns_one_stamp(): void
    {
        $this->pay($this->checkIn()->json('data.id'))
            ->assertCreated()
            ->assertJsonPath('data.customer.loyalty_stamps', 1);
        $this->pay($this->checkIn()->json('data.id'), extra: ['method' => 'benefit'])->assertCreated();

        $this->assertSame(2, $this->stamps());
    }

    public function test_a_visit_without_a_customer_earns_nothing(): void
    {
        $orderId = $this->checkIn(['vehicle_id' => null, 'plate_number' => '77-111', 'vehicle_size_id' => $this->sedan->id])->json('data.id');

        $this->pay($orderId)->assertCreated();

        $this->assertSame(0, $this->stamps());
    }

    public function test_the_free_wash_covers_the_wash_not_the_add_ons_and_uses_up_the_stamps(): void
    {
        $this->giveStamps(4);
        $orderId = $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])->json('data.id');

        $this->pay($orderId, extra: ['use_loyalty_reward' => true])
            ->assertCreated()
            ->assertJsonPath('data.invoice.subtotal', 2500)
            ->assertJsonPath('data.invoice.discount_total', 2000)
            ->assertJsonPath('data.invoice.total', 500)
            ->assertJsonPath('data.invoice.vat_amount', 45)
            ->assertJsonPath('data.customer.loyalty_stamps', 1);

        $this->assertSame(1, $this->stamps(), 'the free visit earns no stamp of its own');
        $this->assertDatabaseHas('invoices', ['total' => 500, 'loyalty_reward' => true]);
    }

    public function test_a_fully_free_visit_issues_an_invoice_with_nothing_to_pay_and_leaves_the_drawer_alone(): void
    {
        $this->giveStamps(3);

        $this->pay($this->checkIn()->json('data.id'), extra: ['use_loyalty_reward' => true])
            ->assertCreated()
            ->assertJsonPath('data.is_paid', true)
            ->assertJsonPath('data.invoice.total', 0)
            ->assertJsonPath('data.invoice.vat_amount', 0);

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/shifts/current?branch_id={$this->branch->id}")
            ->assertJsonPath('data.cash_taken', 0)
            ->assertJsonPath('data.expected_cash', 0);
    }

    public function test_the_free_wash_needs_enough_stamps_and_nothing_is_recorded_without_them(): void
    {
        $this->giveStamps(2);

        $this->pay($this->checkIn()->json('data.id'), extra: ['use_loyalty_reward' => true])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('loyalty');

        $this->assertDatabaseCount('invoices', 0);
        $this->assertSame(2, $this->stamps());
    }

    public function test_the_free_wash_needs_no_discount_permission_but_cannot_join_another_discount(): void
    {
        $this->giveStamps(3);
        $receptionistLimitIgnored = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branch]);

        $this->pay($this->checkIn()->json('data.id'), $receptionistLimitIgnored, [
            'use_loyalty_reward' => true,
            'discount_percent_bps' => 1000,
            'discount_reason' => 'Regular',
        ])->assertUnprocessable()->assertJsonValidationErrors('loyalty');

        $this->pay($this->checkIn()->json('data.id'), $receptionistLimitIgnored, ['use_loyalty_reward' => true])->assertCreated();
    }

    public function test_a_package_is_not_covered_but_still_earns_a_stamp(): void
    {
        $this->giveStamps(3);
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Owner));
        $packageId = $this->postJson('/api/v1/services', [
            'name' => 'VIP',
            'is_package' => true,
            'package_discount_type' => 'percent',
            'package_discount_value' => 1000,
            'package_service_ids' => [$this->wash->id, $this->freshener->id],
        ])->assertCreated()->json('data.id');
        $orderId = $this->checkIn(['items' => [['service_id' => $packageId]]])->json('data.id');

        $this->pay($orderId, extra: ['use_loyalty_reward' => true])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('loyalty');

        $this->pay($orderId)->assertCreated();
        $this->assertSame(4, $this->stamps());
    }

    public function test_turning_the_card_off_stops_earning_and_rewards_and_keeps_the_stamps(): void
    {
        $this->giveStamps(3);
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);

        Sanctum::actingAs($owner);
        $this->patchJson('/api/v1/settings', ['loyalty_enabled' => false, 'loyalty_washes_required' => 5])
            ->assertOk()
            ->assertJsonPath('data.loyalty_enabled', false)
            ->assertJsonPath('data.loyalty_washes_required', 5);
        $this->patchJson('/api/v1/settings', ['loyalty_washes_required' => 1])->assertUnprocessable()->assertJsonValidationErrors('loyalty_washes_required');

        $this->pay($this->checkIn()->json('data.id'), extra: ['use_loyalty_reward' => true])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('loyalty');
        $this->pay($this->checkIn()->json('data.id'))->assertCreated();
        $this->assertSame(3, $this->stamps());

        Sanctum::actingAs($this->cashier);
        $this->patchJson('/api/v1/settings', ['loyalty_enabled' => true])->assertForbidden();
    }
}
