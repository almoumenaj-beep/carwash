<?php

namespace Tests\Feature;

use App\Domain\Expenses\Enums\RecurrenceFrequency;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Expenses\Models\RecurringExpense;
use App\Domain\Identity\Enums\DefaultRole;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class RecurringExpenseTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $owner;

    private ExpenseCategory $rent;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->rent = $this->inTenant(fn () => ExpenseCategory::factory()->create(['name' => 'Rent']));
    }

    public function test_the_owner_schedules_a_monthly_rent(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/recurring-expenses', [
            'branch_id' => $this->branch->id,
            'expense_category_id' => $this->rent->id,
            'amount' => 450000,
            'frequency' => 'monthly',
            'next_due_on' => '2026-12-01',
            'description' => 'Shop rent',
        ])
            ->assertCreated()
            ->assertJsonPath('data.frequency', 'monthly')
            ->assertJsonPath('data.next_due_on', '2026-12-01')
            ->assertJsonPath('data.category.name', 'Rent');

        $this->getJson('/api/v1/recurring-expenses')->assertJsonCount(1, 'data');
    }

    public function test_due_schedules_record_owed_expenses_and_catch_up_missed_dates(): void
    {
        $today = CarbonImmutable::now($this->tenant->timezone)->startOfDay();
        $schedule = $this->inTenant(fn () => RecurringExpense::factory()->create([
            'branch_id' => $this->branch->id,
            'expense_category_id' => $this->rent->id,
            'amount' => 450000,
            'frequency' => RecurrenceFrequency::Weekly,
            'next_due_on' => $today->subWeeks(2)->toDateString(),
            'created_by' => $this->owner->id,
        ]));
        $this->inTenant(fn () => RecurringExpense::factory()->create([
            'branch_id' => $this->branch->id,
            'expense_category_id' => $this->rent->id,
            'next_due_on' => $today->addDay()->toDateString(),
            'created_by' => $this->owner->id,
        ]));

        $this->artisan('expenses:generate-recurring')->assertSuccessful();
        $this->artisan('expenses:generate-recurring')->assertSuccessful();

        $expenses = $this->inTenant(fn () => Expense::query()->orderBy('spent_on')->get());
        $this->assertCount(3, $expenses);
        $this->assertSame($today->subWeeks(2)->toDateString(), $expenses[0]->spent_on->toDateString());
        $this->assertSame($today->toDateString(), $expenses[2]->spent_on->toDateString());
        $this->assertFalse($expenses[0]->isPaid());
        $this->assertSame($schedule->id, $expenses[0]->recurring_expense_id);
        $this->assertSame($today->addWeek()->toDateString(), $schedule->fresh()->next_due_on->toDateString());
    }

    public function test_monthly_dates_keep_their_day_where_the_month_allows(): void
    {
        $this->assertSame('2027-02-28', RecurrenceFrequency::Monthly->after(CarbonImmutable::parse('2027-01-31'))->toDateString());
        $this->assertSame('2026-12-15', RecurrenceFrequency::Monthly->after(CarbonImmutable::parse('2026-11-15'))->toDateString());
        $this->assertSame('2028-02-28', RecurrenceFrequency::Yearly->after(CarbonImmutable::parse('2027-02-28'))->toDateString());
    }

    public function test_paused_schedules_record_nothing_and_only_approvers_manage_schedules(): void
    {
        $this->inTenant(fn () => RecurringExpense::factory()->create([
            'branch_id' => $this->branch->id,
            'expense_category_id' => $this->rent->id,
            'next_due_on' => now()->subDay()->toDateString(),
            'is_active' => false,
            'created_by' => $this->owner->id,
        ]));

        $this->artisan('expenses:generate-recurring')->assertSuccessful();
        $this->assertSame(0, $this->inTenant(fn () => Expense::query()->count()));

        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]));
        $this->postJson('/api/v1/recurring-expenses', [
            'branch_id' => $this->branch->id,
            'expense_category_id' => $this->rent->id,
            'amount' => 1000,
            'frequency' => 'weekly',
            'next_due_on' => '2026-12-01',
        ])->assertForbidden();
    }
}
