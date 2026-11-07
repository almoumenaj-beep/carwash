<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Sales\Models\Invoice;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class InvoiceRefundTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $manager;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
    }

    /**
     * The manager pays for a wash (2.000) on their own shift, with 10.000 in the drawer, and gets its invoice.
     *
     * @param  array<string, mixed>  $extra
     * @return array{order: string, invoice: string}
     */
    private function paidWash(array $extra = []): array
    {
        $this->openShift();
        $orderId = $this->checkIn()->json('data.id');
        $invoiceId = $this->pay($orderId, $this->manager, $extra)->assertCreated()->json('data.invoice.id');

        return ['order' => $orderId, 'invoice' => $invoiceId];
    }

    private function openShift(): void
    {
        Sanctum::actingAs($this->manager);
        $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 10000]);
    }

    private function refund(string $invoiceId, ?User $as = null): TestResponse
    {
        Sanctum::actingAs($as ?? $this->manager);

        return $this->postJson("/api/v1/invoices/{$invoiceId}/refund", ['reason' => 'Paid by mistake']);
    }

    private function shift(): TestResponse
    {
        Sanctum::actingAs($this->manager);

        return $this->getJson("/api/v1/shifts/current?branch_id={$this->branch->id}");
    }

    public function test_a_cash_refund_comes_out_of_the_drawer_and_the_order_can_be_collected_again(): void
    {
        ['order' => $orderId, 'invoice' => $invoiceId] = $this->paidWash();
        $this->shift()->assertJsonPath('data.expected_cash', 12000);

        $this->refund($invoiceId)->assertOk()->assertJsonPath('data.reference', 'MAIN-INV-1');

        $this->shift()
            ->assertJsonPath('data.cash_taken', 2000)
            ->assertJsonPath('data.cash_refunded', 2000)
            ->assertJsonPath('data.expected_cash', 10000);
        $this->assertDatabaseHas('activity_log', ['event' => 'invoice.refunded', 'subject_id' => $invoiceId]);

        $this->getJson("/api/v1/orders/{$orderId}")
            ->assertJsonPath('data.is_paid', false)
            ->assertJsonPath('data.invoice', null)
            ->assertJsonPath('data.refunds.0.reference', 'MAIN-INV-1')
            ->assertJsonPath('data.refunds.0.amount', 2000)
            ->assertJsonPath('data.refunds.0.reason', 'Paid by mistake');

        // Collected again by the right method, under a new invoice.
        $this->pay($orderId, $this->manager, ['method' => 'benefit'])
            ->assertCreated()
            ->assertJsonPath('data.invoice.reference', 'MAIN-INV-2')
            ->assertJsonPath('data.is_paid', true);
    }

    public function test_a_card_refund_leaves_the_drawer_alone(): void
    {
        ['invoice' => $invoiceId] = $this->paidWash(['method' => 'card']);

        $this->refund($invoiceId)->assertOk();

        $this->shift()->assertJsonPath('data.expected_cash', 10000)->assertJsonPath('data.refunds', 2000);
    }

    public function test_a_refund_is_counted_on_the_day_it_was_given_not_the_day_of_the_sale(): void
    {
        $this->travelTo(CarbonImmutable::parse('2026-11-03 10:00', 'Asia/Bahrain'));
        ['invoice' => $invoiceId] = $this->paidWash();

        $this->travelTo(CarbonImmutable::parse('2026-11-04 10:00', 'Asia/Bahrain'));
        $this->refund($invoiceId)->assertOk();

        Sanctum::actingAs($this->owner);
        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}&date=2026-11-03")
            ->assertJsonPath('data.totals.sales', 2000)
            ->assertJsonPath('data.totals.refunds', 0)
            ->assertJsonPath('data.totals.net', 2000);
        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}&date=2026-11-04")
            ->assertJsonPath('data.totals.sales', 0)
            ->assertJsonPath('data.totals.refunds', 2000)
            ->assertJsonPath('data.totals.net', -2000);

        $this->getJson("/api/v1/reports/profit-loss?branch_id={$this->branch->id}&from=2026-11-03&to=2026-11-04")
            ->assertJsonPath('data.revenue.sales', 2000)
            ->assertJsonPath('data.revenue.refunds', 2000)
            ->assertJsonPath('data.revenue.vat', 0)
            ->assertJsonPath('data.revenue.net_sales', 0)
            ->assertJsonPath('data.by_branch.0.net_sales', 0)
            ->assertJsonCount(0, 'data.by_service');

        $this->getJson("/api/v1/reports/cash-flow?branch_id={$this->branch->id}&from=2026-11-03&to=2026-11-04")
            ->assertJsonPath('data.inflow.total', 2000)
            ->assertJsonPath('data.outflow.total', 2000)
            ->assertJsonPath('data.outflow.by_method.0', ['method' => 'refund', 'amount' => 2000])
            ->assertJsonPath('data.net', 0)
            ->assertJsonPath('data.by_day.1', ['date' => '2026-11-04', 'inflow' => 0, 'outflow' => 2000]);
    }

    public function test_a_refund_is_given_once_needs_a_reason_and_enough_cash(): void
    {
        ['invoice' => $invoiceId] = $this->paidWash();

        Sanctum::actingAs($this->manager);
        $this->postJson("/api/v1/invoices/{$invoiceId}/refund", [])->assertUnprocessable()->assertJsonValidationErrors('reason');

        $this->refund($invoiceId)->assertOk();
        $this->refund($invoiceId)->assertUnprocessable()->assertJsonValidationErrors('invoice');
        $this->assertDatabaseCount('refunds', 1);
    }

    public function test_cash_cannot_be_refunded_from_a_drawer_without_it_or_without_a_shift(): void
    {
        ['invoice' => $invoiceId] = $this->paidWash();

        // The owner has no shift open.
        $this->refund($invoiceId, $this->owner)->assertUnprocessable()->assertJsonValidationErrors('shift');

        // The owner's own drawer holds too little.
        Sanctum::actingAs($this->owner);
        $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 500])->assertCreated();
        $this->refund($invoiceId, $this->owner)->assertUnprocessable()->assertJsonValidationErrors('invoice');

        $this->assertDatabaseCount('refunds', 0);
        $this->assertNull($this->inTenant(fn () => Invoice::query()->sole()->refunded_at));
    }

    public function test_only_staff_with_the_permission_refund_at_their_branches(): void
    {
        ['invoice' => $invoiceId] = $this->paidWash();

        $this->refund($invoiceId, $this->cashier)->assertForbidden();
        $this->refund($invoiceId, $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->otherBranch]))->assertForbidden();
    }

    public function test_points_earned_go_back_and_points_spent_return(): void
    {
        $this->tenant->forceFill(['points_enabled' => true, 'points_earn_amount' => 1000, 'points_redeem_points' => 10, 'points_redeem_value' => 1000])->save();
        $this->customer->forceFill(['points_balance' => 10])->save();

        // Spends 10 points for 1.000 off the 2.000 wash, and earns 1 on the 1.000 paid.
        ['invoice' => $invoiceId] = $this->paidWash(['redeem_points' => 10]);
        $this->assertSame(1, $this->customer->fresh()->points_balance);

        $this->refund($invoiceId)->assertOk();

        $this->assertSame(10, $this->customer->fresh()->points_balance);
        Sanctum::actingAs($this->manager);
        $this->getJson("/api/v1/customers/{$this->customer->id}/points")
            ->assertJsonPath('data.0.type', 'refund')
            ->assertJsonPath('data.0.points', 9);
    }

    public function test_points_already_spent_leave_the_balance_at_zero_not_below(): void
    {
        $this->tenant->forceFill(['points_enabled' => true, 'points_earn_amount' => 1000])->save();
        ['invoice' => $invoiceId] = $this->paidWash();
        $this->assertSame(2, $this->customer->fresh()->points_balance);
        $this->customer->forceFill(['points_balance' => 1])->save();

        $this->refund($invoiceId)->assertOk();

        $this->assertSame(0, $this->customer->fresh()->points_balance);
    }

    /**
     * Three washes for 5.000, sold to the customer by the manager.
     *
     * @return array{membership: string, invoice: string}
     */
    private function soldMembership(): array
    {
        $this->tenant->forceFill(['memberships_enabled' => true])->save();
        Sanctum::actingAs($this->owner);
        $planId = $this->postJson('/api/v1/membership-plans', [
            'name' => '3 washes', 'price' => 5000, 'washes' => 3, 'validity_days' => 30, 'scope' => 'customer', 'service_ids' => [$this->wash->id],
        ])->assertCreated()->json('data.id');

        $this->openShift();
        $membershipId = $this->postJson("/api/v1/customers/{$this->customer->id}/memberships", [
            'membership_plan_id' => $planId, 'branch_id' => $this->branch->id, 'method' => 'cash',
        ])->assertCreated()->json('data.id');

        return ['membership' => $membershipId, 'invoice' => $this->inTenant(fn () => Invoice::query()->sole()->id)];
    }

    public function test_refunding_an_unused_membership_stops_it(): void
    {
        ['invoice' => $invoiceId] = $this->soldMembership();

        $this->refund($invoiceId)->assertOk();

        $this->getJson("/api/v1/customers/{$this->customer->id}/memberships")
            ->assertJsonPath('data.0.is_usable', false)
            ->assertJsonPath('data.0.can_refund', false);
        $this->shift()->assertJsonPath('data.expected_cash', 10000);
    }

    public function test_a_membership_with_washes_taken_cannot_be_refunded_but_a_wash_can_be_returned_to_it(): void
    {
        ['membership' => $membershipId, 'invoice' => $saleId] = $this->soldMembership();
        $orderId = $this->checkIn()->json('data.id');
        $washInvoice = $this->pay($orderId, $this->manager, ['membership_id' => $membershipId])->assertCreated()->json('data.invoice.id');

        $this->refund($saleId)->assertUnprocessable()->assertJsonValidationErrors('invoice');
        $this->getJson("/api/v1/customers/{$this->customer->id}/memberships")
            ->assertJsonPath('data.0.washes_left', 2)
            ->assertJsonPath('data.0.can_refund', false);

        // The wash itself had nothing to pay, so no shift or money is involved in giving it back.
        $this->refund($washInvoice)->assertOk();
        $this->getJson("/api/v1/customers/{$this->customer->id}/memberships")
            ->assertJsonPath('data.0.washes_left', 3)
            ->assertJsonPath('data.0.can_refund', true);
    }

    public function test_a_refunded_order_can_then_be_cancelled_but_a_paid_one_cannot(): void
    {
        ['order' => $orderId, 'invoice' => $invoiceId] = $this->paidWash();

        $this->moveTo($orderId, 'cancelled', $this->owner, ['reason' => 'Left'])->assertUnprocessable();
        $this->refund($invoiceId)->assertOk();
        $this->moveTo($orderId, 'cancelled', $this->owner, ['reason' => 'Left'])->assertOk();
    }
}
