<?php

namespace Tests\Feature;

use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Inventory\Models\InventoryItem;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class FinancialReportsTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $owner;

    private ExpenseCategory $rent;

    private ExpenseCategory $supplies;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo(CarbonImmutable::parse('2026-11-15 10:00', 'Asia/Bahrain'));
        $this->buildCarWash();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->inTenant(function (): void {
            $this->rent = ExpenseCategory::factory()->create(['name' => 'Rent']);
            $this->supplies = ExpenseCategory::factory()->create(['name' => 'Cleaning supplies']);
            $shampoo = InventoryItem::factory()->create(['name' => 'Shampoo', 'unit' => 'L', 'unit_cost' => 1000]);
            $this->wash->materials()->attach($shampoo->id, ['quantity_milli' => 50]);
        });
    }

    /**
     * A wash (2.000) and a wash + freshener with 10% off (2.250), both cash; rent of 10.000 paid in cash,
     * supplies of 3.000 still owed, and last month's rent outside the period.
     */
    private function aPeriodOfBusiness(): void
    {
        $this->pay($this->checkIn()->json('data.id'))->assertCreated();
        $this->pay(
            $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]])->json('data.id'),
            extra: ['discount_percent_bps' => 1000, 'discount_reason' => 'Regular'],
        )->assertCreated();

        Sanctum::actingAs($this->owner);
        $expense = ['branch_id' => $this->branch->id, 'expense_category_id' => $this->rent->id, 'amount' => 10000, 'payment_method' => 'cash'];
        $this->postJson('/api/v1/expenses', $expense)->assertCreated();
        $this->postJson('/api/v1/expenses', [...$expense, 'spent_on' => '2026-10-20'])->assertCreated();
        $this->postJson('/api/v1/expenses', [...$expense, 'expense_category_id' => $this->supplies->id, 'amount' => 3000, 'payment_method' => null])->assertCreated();
    }

    public function test_profit_and_loss_for_this_month_by_category_branch_service_and_washer(): void
    {
        $this->aPeriodOfBusiness();

        $this->getJson('/api/v1/reports/profit-loss')
            ->assertOk()
            ->assertJsonPath('data.from', '2026-11-01')
            ->assertJsonPath('data.to', '2026-11-15')
            ->assertJsonPath('data.revenue.invoices_count', 2)
            ->assertJsonPath('data.revenue.sales', 4250)
            ->assertJsonPath('data.revenue.vat', 182 + 205)
            ->assertJsonPath('data.revenue.net_sales', 3863)
            ->assertJsonPath('data.expenses.total', 13000)
            ->assertJsonPath('data.expenses.owed', 3000)
            ->assertJsonPath('data.expenses.by_category.0.name', 'Rent')
            ->assertJsonPath('data.expenses.by_category.0.amount', 10000)
            ->assertJsonPath('data.expenses.by_category.1.amount', 3000)
            ->assertJsonPath('data.profit', 3863 - 13000)
            ->assertJsonPath('data.margin_bps', -23652)
            ->assertJsonPath('data.by_branch.1.name', $this->branch->name)
            ->assertJsonPath('data.by_branch.1.profit', 3863 - 13000)
            ->assertJsonPath('data.by_service.0.name', 'Exterior wash')
            ->assertJsonPath('data.by_service.0.quantity', 2)
            ->assertJsonPath('data.by_service.0.net_revenue', 1818 + 1636)
            ->assertJsonPath('data.by_service.0.materials', 100)
            ->assertJsonPath('data.by_service.0.profit', 1818 + 1636 - 100)
            ->assertJsonPath('data.by_service.1.net_revenue', 409)
            ->assertJsonPath('data.by_washer.0.name', $this->washer->name)
            ->assertJsonPath('data.by_washer.0.cars', 2)
            ->assertJsonPath('data.by_washer.0.net_revenue', 3863);
    }

    public function test_cash_flow_counts_money_when_it_moves(): void
    {
        $this->aPeriodOfBusiness();

        $this->getJson('/api/v1/reports/cash-flow?from=2026-11-01&to=2026-11-30')
            ->assertOk()
            ->assertJsonPath('data.inflow.total', 4250)
            ->assertJsonPath('data.inflow.by_method.0', ['method' => 'cash', 'amount' => 4250])
            ->assertJsonPath('data.outflow.total', 20000)
            ->assertJsonPath('data.net', 4250 - 20000)
            ->assertJsonPath('data.owed', ['total' => 3000, 'count' => 1])
            ->assertJsonPath('data.by_day', [['date' => '2026-11-15', 'inflow' => 4250, 'outflow' => 20000]]);
    }

    public function test_the_period_is_checked_and_kept_to_the_permission(): void
    {
        Sanctum::actingAs($this->owner);
        $this->getJson('/api/v1/reports/profit-loss?from=2025-01-01&to=2026-01-01')->assertUnprocessable()->assertJsonValidationErrors('to');
        $this->getJson('/api/v1/reports/cash-flow?from=2026-11-10&to=2026-11-01')->assertUnprocessable()->assertJsonValidationErrors('to');

        Sanctum::actingAs($this->cashier);
        $this->getJson('/api/v1/reports/profit-loss')->assertForbidden();
        $this->getJson('/api/v1/reports/cash-flow')->assertForbidden();

        $manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
        Sanctum::actingAs($manager);
        $this->getJson('/api/v1/reports/profit-loss')->assertForbidden();

        $accountant = $this->createStaff($this->tenant, DefaultRole::Accountant, [$this->branch]);
        Sanctum::actingAs($accountant);
        $this->getJson("/api/v1/reports/cash-flow?branch_id={$this->otherBranch->id}")->assertForbidden();
        $this->getJson('/api/v1/reports/cash-flow')->assertOk();
    }
}
