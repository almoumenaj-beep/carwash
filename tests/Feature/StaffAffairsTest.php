<?php

namespace Tests\Feature;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Branch;
use App\Domain\Staff\Models\AttendanceLog;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class StaffAffairsTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $owner;

    private User $manager;

    private ExpenseCategory $wages;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
        $this->wages = $this->inTenant(fn () => ExpenseCategory::factory()->create(['name' => 'Wages']));
    }

    /**
     * @param  array<string, mixed>  $terms
     */
    private function setPayTerms(User $staff, array $terms): void
    {
        Sanctum::actingAs($this->manager);
        $this->putJson("/api/v1/employees/{$staff->id}/pay-terms", $terms)->assertOk();
    }

    /**
     * Checks a car in for the washer (and anyone else given), washes, passes and delivers it this month.
     *
     * @param  list<string>  $staffIds
     */
    private function deliverCar(array $staffIds): string
    {
        $orderId = $this->checkIn(['staff_ids' => $staffIds])->json('data.id');
        $this->pay($orderId)->assertCreated();
        $this->washAndPass($orderId, $this->washer);
        $this->moveTo($orderId, 'delivered', $this->cashier)->assertOk();

        return $orderId;
    }

    public function test_staff_clock_in_and_out_and_managers_see_the_day(): void
    {
        Sanctum::actingAs($this->washer);
        $this->postJson('/api/v1/attendance/clock-in', ['branch_id' => $this->branch->id])->assertCreated();
        $this->postJson('/api/v1/attendance/clock-in', ['branch_id' => $this->branch->id])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('attendance');
        $this->getJson('/api/v1/attendance/me')->assertJsonPath('data.branch.id', $this->branch->id);
        $this->postJson('/api/v1/attendance/clock-in', ['branch_id' => $this->otherBranch->id])->assertForbidden();

        $this->postJson('/api/v1/attendance/clock-out')->assertOk()->assertJsonPath('data.user.id', $this->washer->id);
        $this->getJson('/api/v1/attendance/me')->assertJsonPath('data', null);
        $this->postJson('/api/v1/attendance/clock-out')->assertUnprocessable();

        $this->getJson("/api/v1/attendance?branch_id={$this->branch->id}")->assertForbidden();
        Sanctum::actingAs($this->manager);
        $this->getJson("/api/v1/attendance?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.user.name', $this->washer->name);
    }

    public function test_clocking_out_is_blocked_with_an_open_cash_shift(): void
    {
        Sanctum::actingAs($this->cashier);
        $this->postJson('/api/v1/attendance/clock-in', ['branch_id' => $this->branch->id])->assertCreated();
        $shiftId = $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => 10000])
            ->assertCreated()
            ->json('data.id');

        $this->postJson('/api/v1/attendance/clock-out')->assertUnprocessable()->assertJsonValidationErrors('shift');
        $this->getJson('/api/v1/shifts/mine')->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $shiftId);

        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 10000])->assertOk();
        $this->postJson('/api/v1/attendance/clock-out')->assertOk();
        $this->getJson('/api/v1/shifts/mine')->assertJsonCount(0, 'data');
    }

    /**
     * A finished attendance record, with times in the car wash's time zone.
     */
    private function attended(User $user, Branch $branch, string $in, string $out, bool $auto = false): void
    {
        $this->inTenant(function () use ($user, $branch, $in, $out, $auto): void {
            (new AttendanceLog)->forceFill([
                'user_id' => $user->id,
                'branch_id' => $branch->id,
                'clock_in_at' => CarbonImmutable::parse($in, $this->tenant->timezone)->utc(),
                'clock_out_at' => CarbonImmutable::parse($out, $this->tenant->timezone)->utc(),
                'auto_clocked_out' => $auto,
            ])->save();
        });
    }

    public function test_the_attendance_summary_adds_up_days_and_hours_per_employee_over_a_period(): void
    {
        $this->attended($this->washer, $this->branch, '2026-10-05 08:00', '2026-10-05 12:00');
        $this->attended($this->washer, $this->branch, '2026-10-05 16:00', '2026-10-05 18:00');
        $this->attended($this->washer, $this->branch, '2026-10-06 00:30', '2026-10-06 01:30', auto: true);
        $this->attended($this->cashier, $this->branch, '2026-10-06 08:00', '2026-10-06 18:00');
        $this->attended($this->washer, $this->branch, '2026-10-04 08:00', '2026-10-04 12:00');
        $this->attended($this->washer, $this->branch, '2026-10-07 08:00', '2026-10-07 12:00');
        $this->attended($this->washer, $this->otherBranch, '2026-10-05 13:00', '2026-10-05 14:00');

        Sanctum::actingAs($this->manager);
        $this->getJson("/api/v1/attendance/summary?branch_id={$this->branch->id}&from=2026-10-05&to=2026-10-06")
            ->assertOk()
            ->assertJsonPath('data.total_minutes', 17 * 60)
            ->assertJsonCount(2, 'data.staff')
            ->assertJsonPath('data.staff.0.user.id', $this->cashier->id)
            ->assertJsonPath('data.staff.0.days', 1)
            ->assertJsonPath('data.staff.0.minutes', 600)
            ->assertJsonPath('data.staff.1.user.id', $this->washer->id)
            ->assertJsonPath('data.staff.1.days', 2)
            ->assertJsonPath('data.staff.1.minutes', 420)
            ->assertJsonPath('data.staff.1.auto_clocked_out', 1)
            ->assertJsonCount(3, 'data.staff.1.records');
    }

    public function test_the_attendance_summary_stays_within_permissions_branches_and_a_year(): void
    {
        Sanctum::actingAs($this->washer);
        $this->getJson("/api/v1/attendance/summary?branch_id={$this->branch->id}")->assertForbidden();

        Sanctum::actingAs($this->manager);
        $this->getJson("/api/v1/attendance/summary?branch_id={$this->otherBranch->id}")->assertForbidden();
        $this->getJson("/api/v1/attendance/summary?branch_id={$this->branch->id}&from=2025-01-01&to=2026-01-01")
            ->assertUnprocessable()
            ->assertJsonValidationErrors('to');
        $this->getJson("/api/v1/attendance/summary?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonPath('data.from', now($this->tenant->timezone)->startOfMonth()->toDateString())
            ->assertJsonPath('data.staff', []);
    }

    public function test_managers_set_pay_terms_and_see_their_staff(): void
    {
        $this->setPayTerms($this->washer, ['monthly_salary' => 150000, 'commission_type' => 'per_car', 'commission_value' => 500]);

        $staff = collect($this->getJson('/api/v1/employees')->assertOk()->json('data'))->keyBy('id');
        $this->assertSame(150000, $staff[$this->washer->id]['monthly_salary']);
        $this->assertSame('per_car', $staff[$this->washer->id]['commission_type']);
        $this->assertFalse($staff->has($this->createStaff($this->tenant, DefaultRole::Washer, [$this->otherBranch])->id));

        $this->putJson("/api/v1/employees/{$this->washer->id}/pay-terms", ['monthly_salary' => 1, 'commission_type' => 'percent', 'commission_value' => 10001])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('commission_value');

        Sanctum::actingAs($this->cashier);
        $this->getJson('/api/v1/employees')->assertForbidden();
    }

    public function test_payroll_adds_salary_and_commission_and_paying_fixes_it(): void
    {
        $this->setPayTerms($this->washer, ['monthly_salary' => 150000, 'commission_type' => 'per_car', 'commission_value' => 500]);
        $this->setPayTerms($this->cashier, ['monthly_salary' => 200000, 'commission_type' => 'percent', 'commission_value' => 1000]);
        $this->deliverCar([$this->washer->id]);
        $this->deliverCar([$this->washer->id, $this->cashier->id]);
        $this->checkIn(['staff_ids' => [$this->washer->id]])->assertCreated();

        Sanctum::actingAs($this->owner);
        $now = now($this->tenant->timezone);
        $run = $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])->assertOk();
        $lines = collect($run->json('data.lines'))->keyBy('user.id');

        // Washer: 150.000 salary + 0.500 for the first car + 0.250 (half) for the shared car.
        $this->assertSame(2, $lines[$this->washer->id]['cars_count']);
        $this->assertSame(750, $lines[$this->washer->id]['commission']);
        $this->assertSame(150750, $lines[$this->washer->id]['net']);
        $this->assertArrayNotHasKey('advances', $lines[$this->washer->id]);
        // Cashier: 200.000 + 10% of half the shared 2.000 car = 0.100.
        $this->assertSame(1, $lines[$this->cashier->id]['cars_count']);
        $this->assertSame(100, $lines[$this->cashier->id]['commission']);
        $run->assertJsonPath('data.status', 'draft')->assertJsonPath('data.total_net', 150750 + 200100);

        $this->postJson("/api/v1/payroll-runs/{$run->json('data.id')}/pay", [
            'branch_id' => $this->branch->id,
            'expense_category_id' => $this->wages->id,
            'payment_method' => 'bank_transfer',
        ])->assertOk()->assertJsonPath('data.status', 'paid');

        $this->assertSame(350850, (int) $this->inTenant(fn () => Expense::query()->sum('amount')));
        $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('payroll');

        Sanctum::actingAs($this->manager);
        $this->getJson('/api/v1/payroll-runs')->assertForbidden();
    }

    public function test_cancelling_a_payment_removes_its_expense_and_makes_the_month_a_draft_again(): void
    {
        $withoutApproval = $this->createStaffWithPermissions($this->tenant, [Permission::PayrollRun, Permission::PayrollView]);
        $this->setPayTerms($this->washer, ['monthly_salary' => 150000, 'commission_type' => 'none', 'commission_value' => 0]);
        Sanctum::actingAs($this->owner);
        $now = now($this->tenant->timezone);
        $runId = $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])->json('data.id');
        $pay = ['branch_id' => $this->branch->id, 'expense_category_id' => $this->wages->id, 'payment_method' => 'bank_transfer'];
        $this->postJson("/api/v1/payroll-runs/{$runId}/pay", $pay)->assertOk();

        $expense = $this->inTenant(fn () => Expense::query()->sole());
        $this->getJson('/api/v1/expenses')->assertJsonPath('data.0.source', 'payroll');
        $this->deleteJson("/api/v1/expenses/{$expense->id}")->assertUnprocessable()->assertJsonValidationErrors('expense');

        Sanctum::actingAs($withoutApproval);
        $this->postJson("/api/v1/payroll-runs/{$runId}/cancel-payment")->assertForbidden();

        Sanctum::actingAs($this->owner);
        $this->postJson("/api/v1/payroll-runs/{$runId}/cancel-payment")
            ->assertOk()
            ->assertJsonPath('data.status', 'draft')
            ->assertJsonPath('data.paid_at', null);
        $this->assertSame(0, $this->inTenant(fn () => Expense::query()->count()));
        $this->assertDatabaseHas('activity_log', ['event' => 'payroll.payment_cancelled', 'tenant_id' => $this->tenant->id]);

        $this->postJson("/api/v1/payroll-runs/{$runId}/cancel-payment")->assertUnprocessable()->assertJsonValidationErrors('payroll');

        $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])->assertOk();
        $this->postJson("/api/v1/payroll-runs/{$runId}/pay", $pay)->assertOk()->assertJsonPath('data.status', 'paid');
        $this->assertSame(150000, $this->inTenant(fn () => Expense::query()->sole()->amount));
    }

    public function test_a_percentage_commission_is_taken_of_the_final_invoice_amount(): void
    {
        $this->setPayTerms($this->washer, ['monthly_salary' => 0, 'commission_type' => 'percent', 'commission_value' => 1000]);

        $orderId = $this->checkIn(['staff_ids' => [$this->washer->id]])->json('data.id');
        $this->pay($orderId, extra: ['discount_percent_bps' => 1000, 'discount_reason' => 'Regular'])->assertCreated();
        $this->washAndPass($orderId, $this->washer);
        $this->moveTo($orderId, 'delivered', $this->cashier)->assertOk();

        Sanctum::actingAs($this->owner);
        $now = now($this->tenant->timezone);

        // 10% of the 1.800 paid after 10% off the 2.000 wash, with no salary.
        $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])
            ->assertJsonPath('data.lines.0.base_salary', 0)
            ->assertJsonPath('data.lines.0.commission', 180)
            ->assertJsonPath('data.lines.0.net', 180);
    }

    public function test_roles_say_who_must_clock_in_before_working(): void
    {
        Sanctum::actingAs($this->washer);
        $this->getJson('/api/v1/me')->assertJsonPath('data.requires_attendance', true);

        Sanctum::actingAs($this->owner);
        $this->getJson('/api/v1/me')->assertJsonPath('data.requires_attendance', false);

        $accountant = $this->createStaff($this->tenant, DefaultRole::Accountant, [$this->branch]);
        Sanctum::actingAs($accountant);
        $this->getJson('/api/v1/me')->assertJsonPath('data.requires_attendance', false);

        $washerRole = $this->inTenant(fn () => Role::query()->where('key', DefaultRole::Washer->value)->sole());
        Sanctum::actingAs($this->owner);
        $this->patchJson("/api/v1/roles/{$washerRole->id}", ['requires_attendance' => false])
            ->assertOk()
            ->assertJsonPath('data.requires_attendance', false);
        $this->assertDatabaseHas('activity_log', ['event' => 'role.attendance_requirement_changed']);

        Sanctum::actingAs($this->washer->fresh());
        $this->getJson('/api/v1/me')->assertJsonPath('data.requires_attendance', false);
    }

    public function test_a_draft_follows_new_deliveries_until_it_is_paid(): void
    {
        $this->setPayTerms($this->washer, ['monthly_salary' => 0, 'commission_type' => 'per_car', 'commission_value' => 1000]);
        $now = now($this->tenant->timezone);

        Sanctum::actingAs($this->owner);
        $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])
            ->assertJsonPath('data.lines', []);

        $this->deliverCar([$this->washer->id]);
        Sanctum::actingAs($this->owner);
        $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])
            ->assertJsonPath('data.lines.0.commission', 1000);

        $lastMonth = $now->copy()->subMonthNoOverflow();
        $this->inTenant(fn () => Order::query()->update(['delivered_at' => $lastMonth]));
        $this->postJson('/api/v1/payroll-runs', ['year' => $now->year, 'month' => $now->month])
            ->assertJsonPath('data.lines', []);
    }
}
