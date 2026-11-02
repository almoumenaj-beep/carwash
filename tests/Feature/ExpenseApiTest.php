<?php

namespace Tests\Feature;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Expenses\Models\Supplier;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class ExpenseApiTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $owner;

    private User $manager;

    private ExpenseCategory $supplies;

    private Supplier $supplier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
        $this->inTenant(function (): void {
            $this->supplies = ExpenseCategory::factory()->create(['name' => 'Cleaning supplies']);
            $this->supplier = Supplier::factory()->create(['name' => 'Gulf Chemicals']);
        });
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    private function record(array $overrides = [], ?User $as = null): TestResponse
    {
        Sanctum::actingAs($as ?? $this->manager);

        return $this->postJson('/api/v1/expenses', [
            'branch_id' => $this->branch->id,
            'expense_category_id' => $this->supplies->id,
            'amount' => 3500,
            'payment_method' => 'cash',
            ...$overrides,
        ]);
    }

    public function test_a_manager_records_a_paid_expense(): void
    {
        $this->record(['description' => 'Soap'])
            ->assertCreated()
            ->assertJsonPath('data.amount', 3500)
            ->assertJsonPath('data.is_paid', true)
            ->assertJsonPath('data.payment_method', 'cash')
            ->assertJsonPath('data.category.name', 'Cleaning supplies')
            ->assertJsonPath('data.spent_on', now($this->tenant->timezone)->toDateString())
            ->assertJsonPath('data.created_by.id', $this->manager->id);

        $this->assertDatabaseHas('activity_log', ['event' => 'expense.recorded', 'tenant_id' => $this->tenant->id]);
    }

    public function test_an_expense_without_payment_is_owed_to_its_supplier_and_paid_later(): void
    {
        $expenseId = $this->record(['payment_method' => null, 'supplier_id' => $this->supplier->id, 'amount' => 12000])
            ->assertCreated()
            ->assertJsonPath('data.is_paid', false)
            ->json('data.id');

        $this->getJson('/api/v1/suppliers')->assertJsonPath('data.0.owed', 12000);
        $this->getJson('/api/v1/expenses?status=unpaid')->assertJsonCount(1, 'data')->assertJsonPath('total', 12000);

        $this->postJson("/api/v1/expenses/{$expenseId}/pay", ['payment_method' => 'bank_transfer'])->assertForbidden();

        Sanctum::actingAs($this->owner);
        $this->postJson("/api/v1/expenses/{$expenseId}/pay", ['payment_method' => 'bank_transfer'])
            ->assertOk()
            ->assertJsonPath('data.is_paid', true)
            ->assertJsonPath('data.payment_method', 'bank_transfer');
        $this->postJson("/api/v1/expenses/{$expenseId}/pay", ['payment_method' => 'cash'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('expense');
        $this->getJson('/api/v1/suppliers')->assertJsonPath('data.0.owed', 0);
    }

    public function test_cash_from_the_drawer_needs_an_open_shift_and_lowers_the_expected_cash(): void
    {
        $this->record(['payment_method' => 'cash_drawer'], $this->owner)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['payment_method' => 'Open your shift at this branch to pay from its drawer.']);

        Sanctum::actingAs($this->owner);
        $shiftId = $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 10000])->json('data.id');
        $this->record(['payment_method' => 'cash_drawer', 'amount' => 1500], $this->owner)->assertCreated();

        $this->getJson("/api/v1/shifts/current?branch_id={$this->branch->id}")
            ->assertJsonPath('data.cash_paid_out', 1500)
            ->assertJsonPath('data.expected_cash', 8500);
        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 8500])->assertOk()->assertJsonPath('data.variance', 0);
    }

    public function test_an_expense_counted_in_a_closed_shift_cannot_be_deleted(): void
    {
        Sanctum::actingAs($this->owner);
        $shiftId = $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 5000])->json('data.id');
        $drawerExpense = $this->record(['payment_method' => 'cash_drawer', 'amount' => 1000], $this->owner)->json('data.id');
        $otherExpense = $this->record([], $this->owner)->json('data.id');
        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 4000])->assertOk();

        $this->deleteJson("/api/v1/expenses/{$drawerExpense}")->assertUnprocessable()->assertJsonValidationErrors('expense');
        $this->deleteJson("/api/v1/expenses/{$otherExpense}")->assertNoContent();
        $this->assertDatabaseHas('activity_log', ['event' => 'expense.deleted', 'subject_id' => $otherExpense]);
    }

    public function test_expenses_are_listed_by_period_with_their_total(): void
    {
        $this->record(['amount' => 2000])->assertCreated();
        $this->record(['amount' => 3000, 'spent_on' => now($this->tenant->timezone)->subMonths(2)->toDateString()])->assertCreated();

        $this->getJson('/api/v1/expenses')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('total', 2000);
        $this->getJson('/api/v1/expenses?from='.now()->subYear()->toDateString().'&to='.now($this->tenant->timezone)->toDateString())
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('total', 5000);
    }

    public function test_staff_stay_within_their_permissions_and_branches(): void
    {
        $this->record([], $this->cashier)->assertForbidden();
        $this->record(['branch_id' => $this->otherBranch->id])->assertForbidden();

        Sanctum::actingAs($this->cashier);
        $this->getJson('/api/v1/expenses')->assertForbidden();

        Sanctum::actingAs($this->manager);
        $this->getJson("/api/v1/expenses?branch_id={$this->otherBranch->id}")->assertForbidden();
        $this->postJson('/api/v1/suppliers', ['name' => 'X'])->assertForbidden();
    }

    public function test_categories_in_use_are_deactivated_not_deleted(): void
    {
        $this->record()->assertCreated();
        Sanctum::actingAs($this->owner);

        $this->deleteJson("/api/v1/expense-categories/{$this->supplies->id}")
            ->assertUnprocessable()
            ->assertJsonValidationErrors('expense_category');
        $this->patchJson("/api/v1/expense-categories/{$this->supplies->id}", ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);
        $this->record([], $this->owner)->assertUnprocessable()->assertJsonValidationErrors('expense_category_id');

        $unused = $this->postJson('/api/v1/expense-categories', ['name' => 'Marketing'])->assertCreated()->json('data.id');
        $this->deleteJson("/api/v1/expense-categories/{$unused}")->assertNoContent();
    }

    public function test_the_daily_report_shows_expenses_and_net(): void
    {
        $this->pay($this->checkIn()->json('data.id'))->assertCreated();
        $this->record(['amount' => 500])->assertCreated();
        $this->record(['amount' => 700, 'payment_method' => null])->assertCreated();

        Sanctum::actingAs($this->owner);
        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}")
            ->assertJsonPath('data.totals.sales', 2000)
            ->assertJsonPath('data.totals.expenses', 1200)
            ->assertJsonPath('data.totals.net', 800);
    }

    public function test_a_new_tenant_gets_default_categories(): void
    {
        $this->artisan('tenants:provision-defaults')->assertSuccessful();

        $this->assertSame(1, $this->inTenant(fn () => ExpenseCategory::query()->count()));
        $fresh = $this->createTenantWithRoles();
        $this->artisan('tenants:provision-defaults')->assertSuccessful();
        $this->assertSame(8, $this->app->make(TenantContext::class)->run($fresh, fn () => ExpenseCategory::query()->count()));
        $this->assertSame(0, $this->inTenant(fn () => Expense::query()->count()));
    }
}
