<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Sales\Models\CashShift;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class CashShiftAutoCloseTest extends TestCase
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
     * The cashier opens a shift at the main branch at a local time in Bahrain.
     */
    private function openAt(string $localTime, int $float = 10000): void
    {
        $this->travelTo(CarbonImmutable::parse($localTime, 'Asia/Bahrain'));
        Sanctum::actingAs($this->cashier);
        $this->postJson('/api/v1/shifts', ['branch_id' => $this->branch->id, 'opening_float' => $float])->assertCreated();
    }

    private function closeForgottenAt(string $localTime): void
    {
        $this->travelTo(CarbonImmutable::parse($localTime, 'Asia/Bahrain'));
        $this->artisan('cash-shifts:close-forgotten')->assertSuccessful();
    }

    private function shift(): CashShift
    {
        return $this->inTenant(fn () => CashShift::query()->sole());
    }

    public function test_a_forgotten_shift_closes_at_closing_time_without_a_count_and_waits_for_one(): void
    {
        // Tuesday; the branch is open 08:00-22:00.
        $this->openAt('2026-11-03 10:00');
        $this->pay($this->checkIn()->json('data.id'), extra: ['tendered' => 5000])->assertCreated();

        $this->closeForgottenAt('2026-11-03 21:59');
        $this->assertNull($this->shift()->closed_at);

        $this->closeForgottenAt('2026-11-03 22:10');
        $shift = $this->shift();
        $this->assertTrue($shift->auto_closed);
        $this->assertNull($shift->closed_by);
        $this->assertSame(12000, $shift->expected_cash);
        $this->assertNull($shift->counted_cash);
        $this->assertNull($shift->variance);
        $this->assertSame('2026-11-03 22:00', $shift->closed_at->setTimezone('Asia/Bahrain')->format('Y-m-d H:i'));

        Sanctum::actingAs($this->owner);
        $this->getJson("/api/v1/shifts?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonPath('data.0.auto_closed', true);
    }

    public function test_it_stays_on_the_daily_report_until_the_owner_enters_the_real_count(): void
    {
        $this->openAt('2026-11-03 10:00');
        $this->closeForgottenAt('2026-11-03 22:10');
        $shiftId = $this->shift()->id;

        // Later days still show it, until it is counted.
        $this->travelTo(CarbonImmutable::parse('2026-11-05 09:00', 'Asia/Bahrain'));
        Sanctum::actingAs($this->owner);
        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}")
            ->assertJsonCount(1, 'data.uncounted_shifts')
            ->assertJsonPath('data.uncounted_shifts.0.id', $shiftId)
            ->assertJsonPath('data.uncounted_shifts.0.expected_cash', 10000);

        $this->postJson("/api/v1/shifts/{$shiftId}/count", ['counted_cash' => 9500])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('note');
        $this->postJson("/api/v1/shifts/{$shiftId}/count", ['counted_cash' => 9500, 'note' => 'Short after the weekend'])
            ->assertOk()
            ->assertJsonPath('data.counted_cash', 9500)
            ->assertJsonPath('data.variance', -500);

        $this->getJson("/api/v1/reports/daily-sales?branch_id={$this->branch->id}")->assertJsonCount(0, 'data.uncounted_shifts');
        $this->postJson("/api/v1/shifts/{$shiftId}/count", ['counted_cash' => 10000])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('shift');
        $this->assertDatabaseHas('activity_log', ['event' => 'cash_shift.counted', 'subject_id' => $shiftId]);
    }

    public function test_only_the_owner_and_managers_of_the_branch_enter_the_count(): void
    {
        $this->openAt('2026-11-03 10:00');
        $this->closeForgottenAt('2026-11-03 22:10');
        $shiftId = $this->shift()->id;

        Sanctum::actingAs($this->cashier);
        $this->postJson("/api/v1/shifts/{$shiftId}/count", ['counted_cash' => 10000])->assertForbidden();

        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Accountant, [$this->branch]));
        $this->postJson("/api/v1/shifts/{$shiftId}/count", ['counted_cash' => 10000])->assertForbidden();

        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->otherBranch]));
        $this->postJson("/api/v1/shifts/{$shiftId}/count", ['counted_cash' => 10000])->assertForbidden();

        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]));
        $this->postJson("/api/v1/shifts/{$shiftId}/count", ['counted_cash' => 10000])->assertOk()->assertJsonPath('data.variance', 0);
    }

    public function test_a_shift_the_cashier_counted_cannot_be_counted_again(): void
    {
        $this->openAt('2026-11-03 10:00');
        $shiftId = $this->shift()->id;
        Sanctum::actingAs($this->cashier);
        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 10000])->assertOk();

        Sanctum::actingAs($this->owner);
        $this->postJson("/api/v1/shifts/{$shiftId}/count", ['counted_cash' => 1])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('shift');
    }

    public function test_a_shift_with_payments_after_closing_time_is_not_closed_before_them(): void
    {
        $this->openAt('2026-11-03 10:00');
        $this->travelTo(CarbonImmutable::parse('2026-11-05 11:00', 'Asia/Bahrain'));
        $this->pay($this->checkIn()->json('data.id'))->assertCreated();

        $this->closeForgottenAt('2026-11-05 11:05');
        $this->assertSame('2026-11-05 11:00', $this->shift()->closed_at->setTimezone('Asia/Bahrain')->format('Y-m-d H:i'));
    }

    public function test_cashiers_who_closed_their_own_shift_are_left_alone(): void
    {
        $this->openAt('2026-11-03 10:00');
        $shiftId = $this->shift()->id;

        Sanctum::actingAs($this->cashier);
        $this->postJson("/api/v1/shifts/{$shiftId}/close", ['counted_cash' => 10000])->assertOk();

        $this->closeForgottenAt('2026-11-04 09:00');
        $this->assertFalse($this->shift()->auto_closed);
    }
}
