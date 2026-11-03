<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Staff\Models\AttendanceLog;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class AttendanceAutoClockOutTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $manager;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
    }

    /**
     * The washer clocks in at the main branch at a local time in Bahrain.
     */
    private function clockInAt(string $localTime): void
    {
        $this->travelTo(CarbonImmutable::parse($localTime, 'Asia/Bahrain'));
        Sanctum::actingAs($this->washer);
        $this->postJson('/api/v1/attendance/clock-in', ['branch_id' => $this->branch->id])->assertCreated();
    }

    private function closeForgottenAt(string $localTime): void
    {
        $this->travelTo(CarbonImmutable::parse($localTime, 'Asia/Bahrain'));
        $this->artisan('attendance:close-forgotten')->assertSuccessful();
    }

    private function log(): AttendanceLog
    {
        return $this->inTenant(fn () => AttendanceLog::query()->sole());
    }

    public function test_forgotten_attendance_ends_at_closing_time_and_is_marked_automatic(): void
    {
        // Tuesday; the branch is open 08:00–22:00.
        $this->clockInAt('2026-11-03 10:00');

        $this->closeForgottenAt('2026-11-03 21:59');
        $this->assertNull($this->log()->clock_out_at);

        $this->closeForgottenAt('2026-11-03 22:10');
        $this->assertTrue($this->log()->auto_clocked_out);
        $this->assertSame('2026-11-03 22:00', $this->log()->clock_out_at->setTimezone('Asia/Bahrain')->format('Y-m-d H:i'));

        Sanctum::actingAs($this->manager);
        $this->getJson("/api/v1/attendance?branch_id={$this->branch->id}&date=2026-11-03")
            ->assertOk()
            ->assertJsonPath('data.0.auto_clocked_out', true)
            ->assertJsonPath('data.0.minutes', 12 * 60);
    }

    public function test_a_branch_open_past_midnight_closes_the_next_morning(): void
    {
        $this->branch->update(['opening_hours' => [...$this->branch->opening_hours, 'tue' => ['opens' => '16:00', 'closes' => '02:00']]]);
        $this->clockInAt('2026-11-03 23:00');

        $this->closeForgottenAt('2026-11-04 01:00');
        $this->assertNull($this->log()->clock_out_at);

        $this->closeForgottenAt('2026-11-04 02:15');
        $this->assertSame('2026-11-04 02:00', $this->log()->clock_out_at->setTimezone('Asia/Bahrain')->format('Y-m-d H:i'));
    }

    public function test_clocking_in_on_a_closed_day_or_after_closing_ends_at_midnight(): void
    {
        $this->clockInAt('2026-11-03 22:30');

        $this->closeForgottenAt('2026-11-04 00:05');
        $this->assertTrue($this->log()->auto_clocked_out);
        $this->assertSame('2026-11-04 00:00', $this->log()->clock_out_at->setTimezone('Asia/Bahrain')->format('Y-m-d H:i'));
    }

    public function test_staff_who_clocked_out_themselves_are_left_alone(): void
    {
        $this->clockInAt('2026-11-03 10:00');
        $this->postJson('/api/v1/attendance/clock-out')->assertOk();

        $this->closeForgottenAt('2026-11-04 09:00');
        $this->assertFalse($this->log()->auto_clocked_out);
        $this->assertSame('2026-11-03 10:00', $this->log()->clock_out_at->setTimezone('Asia/Bahrain')->format('Y-m-d H:i'));
    }
}
