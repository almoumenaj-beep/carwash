<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class OrderCheckoutTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
    }

    /**
     * A sedan checked in for an exterior wash and an air freshener: 2.500 BHD including VAT.
     */
    private function washAndFreshener(): string
    {
        return $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])->json('data.id');
    }

    public function test_cash_payment_issues_an_invoice_with_the_vat_included_in_the_price(): void
    {
        $orderId = $this->washAndFreshener();

        $this->pay($orderId, extra: ['tendered' => 3000])
            ->assertCreated()
            ->assertJsonPath('data.is_paid', true)
            ->assertJsonPath('data.invoice.reference', 'MAIN-INV-1')
            ->assertJsonPath('data.invoice.subtotal', 2500)
            ->assertJsonPath('data.invoice.total', 2500)
            ->assertJsonPath('data.invoice.vat_rate_bps', 1000)
            ->assertJsonPath('data.invoice.vat_amount', 227)
            ->assertJsonPath('data.invoice.payments.0.method', 'cash')
            ->assertJsonPath('data.invoice.payments.0.amount', 2500)
            ->assertJsonPath('data.invoice.payments.0.change_given', 500);

        $this->assertDatabaseCount('invoice_lines', 2);
        $this->assertDatabaseHas('activity_log', ['event' => 'invoice.issued', 'tenant_id' => $this->tenant->id]);
    }

    public function test_vat_is_added_on_top_when_prices_exclude_it(): void
    {
        $this->tenant->forceFill(['prices_include_vat' => false])->save();

        $this->pay($this->washAndFreshener())
            ->assertCreated()
            ->assertJsonPath('data.invoice.vat_amount', 250)
            ->assertJsonPath('data.invoice.total', 2750);
    }

    public function test_a_cashier_discounts_within_their_limit_and_gives_a_reason(): void
    {
        $orderId = $this->washAndFreshener();

        $this->pay($orderId, extra: ['discount_amount' => 300])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['discount_amount' => 'Your discount limit is 10%.']);
        $this->pay($orderId, extra: ['discount_amount' => 250])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('discount_reason');

        $this->pay($orderId, extra: ['discount_percent_bps' => 1000, 'discount_reason' => 'Regular customer'])
            ->assertCreated()
            ->assertJsonPath('data.invoice.discount_total', 250)
            ->assertJsonPath('data.invoice.discount_reason', 'Regular customer')
            ->assertJsonPath('data.invoice.total', 2250)
            ->assertJsonPath('data.invoice.vat_amount', 205);
    }

    public function test_the_owner_may_give_any_discount_and_staff_without_the_permission_none(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->pay($this->washAndFreshener(), $owner, ['discount_amount' => 2500, 'discount_reason' => 'Complaint'])
            ->assertCreated()
            ->assertJsonPath('data.invoice.total', 0);

        $this->defaultRoleOf($this->tenant, DefaultRole::Cashier)->revokePermissionTo('pos.discount');
        $this->pay($this->washAndFreshener(), extra: ['discount_amount' => 100, 'discount_reason' => 'x'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['discount_amount' => 'You are not allowed to give discounts.']);
    }

    public function test_cash_received_must_cover_the_total(): void
    {
        $this->pay($this->washAndFreshener(), extra: ['tendered' => 2000])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('tendered');

        $this->assertDatabaseCount('invoices', 0);
    }

    public function test_an_order_is_paid_once_and_numbers_count_up_per_branch(): void
    {
        $first = $this->washAndFreshener();
        $this->pay($first)->assertCreated();
        $this->pay($first)->assertUnprocessable()->assertJsonValidationErrors(['order' => 'This order is already paid.']);

        $this->pay($this->washAndFreshener())->assertJsonPath('data.invoice.reference', 'MAIN-INV-2');
    }

    public function test_a_car_is_handed_over_only_once_paid(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        $this->moveTo($orderId, 'in_progress', $this->washer);
        $this->moveTo($orderId, 'ready', $this->washer)->assertJsonPath('data.allowed_next', ['in_progress']);

        $this->moveTo($orderId, 'delivered', $this->cashier)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['status' => 'Collect the payment before handing the car over.']);

        $this->pay($orderId, extra: ['deliver' => true])
            ->assertCreated()
            ->assertJsonPath('data.status', 'delivered');
        $this->assertNotNull($this->customer->fresh()->last_visit_at);
    }

    public function test_paying_before_the_wash_leaves_the_car_in_the_queue(): void
    {
        $orderId = $this->checkIn()->json('data.id');

        $this->pay($orderId, extra: ['deliver' => true])
            ->assertCreated()
            ->assertJsonPath('data.status', 'waiting')
            ->assertJsonPath('data.allowed_next', ['in_progress']);
    }

    public function test_a_paid_order_cannot_be_cancelled_or_have_its_services_changed(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        $this->pay($orderId)->assertCreated();
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);

        $this->moveTo($orderId, 'cancelled', $manager, ['reason' => 'Left'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
        $this->patchJson("/api/v1/orders/{$orderId}", ['items' => [['service_id' => $this->freshener->id], ['service_id' => $this->wash->id]]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items' => 'Services cannot be changed after payment.']);
    }

    public function test_a_cancelled_order_cannot_be_paid(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
        $this->moveTo($orderId, 'cancelled', $manager, ['reason' => 'Left']);

        $this->pay($orderId, $manager)->assertUnprocessable()->assertJsonValidationErrors('order');
    }

    public function test_only_till_staff_of_the_branch_take_payment(): void
    {
        $orderId = $this->checkIn()->json('data.id');

        $this->pay($orderId, $this->washer)->assertForbidden();
        $this->pay($orderId, $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->otherBranch]))->assertForbidden();
        $this->pay($orderId, $this->createStaff($this->createTenantWithRoles(), DefaultRole::Owner))->assertNotFound();
    }
}
