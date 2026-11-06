<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Sales\Models\Invoice;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class DailySalesReportTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
    }

    /**
     * Today: a wash paid in full, a wash + freshener paid with a 10% discount, one car still waiting
     * and one cancelled.
     */
    private function aDayOfSales(): void
    {
        $this->pay($this->checkIn()->json('data.id'))->assertCreated();
        $this->pay(
            $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])->json('data.id'),
            extra: ['discount_percent_bps' => 1000, 'discount_reason' => 'Regular'],
        )->assertCreated();
        $this->checkIn()->assertCreated();
        $cancelled = $this->checkIn()->json('data.id');
        $this->moveTo($cancelled, 'cancelled', $this->owner, ['reason' => 'Left']);
    }

    public function test_the_day_separates_cash_card_and_benefit(): void
    {
        $this->pay($this->checkIn()->json('data.id'))->assertCreated();
        $this->pay($this->checkIn()->json('data.id'), extra: ['method' => 'card'])->assertCreated();
        $this->pay($this->checkIn()->json('data.id'), extra: ['method' => 'benefit'])->assertCreated();
        Sanctum::actingAs($this->owner);

        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonPath('data.totals.sales', 6000)
            ->assertJsonPath('data.totals.cash_collected', 2000)
            ->assertJsonPath('data.totals.card_collected', 2000)
            ->assertJsonPath('data.totals.benefit_collected', 2000);
    }

    public function test_the_day_shows_sales_cars_services_cashiers_washers_and_hours(): void
    {
        $this->aDayOfSales();
        Sanctum::actingAs($this->owner);

        $response = $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}")->assertOk();

        $response
            ->assertJsonPath('data.totals.invoices_count', 2)
            ->assertJsonPath('data.totals.gross', 4500)
            ->assertJsonPath('data.totals.discounts', 250)
            ->assertJsonPath('data.totals.sales', 4250)
            ->assertJsonPath('data.totals.vat', 182 + 205)
            ->assertJsonPath('data.totals.cash_collected', 4250)
            ->assertJsonPath('data.totals.average_ticket', 2125)
            ->assertJsonPath('data.cars.checked_in', 4)
            ->assertJsonPath('data.cars.delivered', 0)
            ->assertJsonPath('data.cars.cancelled', 1)
            ->assertJsonPath('data.cars.in_queue', 3)
            ->assertJsonPath('data.by_service.0.name', 'Exterior wash')
            ->assertJsonPath('data.by_service.0.quantity', 2)
            ->assertJsonPath('data.by_service.0.revenue', 4000)
            ->assertJsonPath('data.by_service.1.name', 'Air freshener')
            ->assertJsonPath('data.by_cashier.0.name', $this->cashier->name)
            ->assertJsonPath('data.by_cashier.0.invoices', 2)
            ->assertJsonPath('data.by_cashier.0.total', 4250)
            ->assertJsonPath('data.by_washer.0.name', $this->washer->name)
            ->assertJsonPath('data.by_washer.0.cars', 3);
        $this->assertSame(4250, array_sum(array_column($response->json('data.by_hour'), 'total')));
    }

    public function test_another_day_is_empty_and_today_is_the_default(): void
    {
        $this->aDayOfSales();
        Sanctum::actingAs($this->owner);

        $this->getJson('/api/v1/reports/daily-sales?date='.now($this->tenant->timezone)->subDay()->toDateString())
            ->assertOk()
            ->assertJsonPath('data.totals.invoices_count', 0)
            ->assertJsonPath('data.totals.average_ticket', 0)
            ->assertJsonPath('data.by_service', []);

        $this->getJson('/api/v1/reports/daily-sales')
            ->assertOk()
            ->assertJsonPath('data.date', now($this->tenant->timezone)->toDateString())
            ->assertJsonPath('data.branch_id', null)
            ->assertJsonPath('data.totals.invoices_count', 2);
    }

    public function test_the_day_follows_the_car_washs_time_zone(): void
    {
        $this->aDayOfSales();
        $localMidnight = now($this->tenant->timezone)->startOfDay();
        $this->inTenant(fn () => Invoice::query()->limit(1)->update(['issued_at' => $localMidnight->copy()->subMinute()->utc()]));
        Sanctum::actingAs($this->owner);

        $this->getJson('/api/v1/reports/daily-sales')->assertJsonPath('data.totals.invoices_count', 1);
        $this->getJson('/api/v1/reports/daily-sales?date='.$localMidnight->copy()->subDay()->toDateString())
            ->assertJsonPath('data.totals.invoices_count', 1);
    }

    public function test_reports_need_the_permission_and_stay_within_the_users_branches(): void
    {
        $this->aDayOfSales();

        Sanctum::actingAs($this->cashier);
        $this->getJson('/api/v1/reports/daily-sales')->assertForbidden();

        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->otherBranch]);
        Sanctum::actingAs($manager);
        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}")->assertForbidden();
        $this->getJson('/api/v1/reports/daily-sales')->assertOk()->assertJsonPath('data.totals.invoices_count', 0);

        Sanctum::actingAs($this->createStaff($this->createTenantWithRoles(), DefaultRole::Owner));
        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}")->assertNotFound();
    }
}
