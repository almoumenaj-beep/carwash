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

    public function test_a_forgotten_shift_closes_at_closing_time_with_the_expected_cash_and_is_marked_automatic(): void
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
        $this->assertSame(12000, $shift->counted_cash);
        $this->assertSame(0, $shift->variance);
        $this->assertNotNull($shift->close_note);
        $this->assertSame('2026-11-03 22:00', $shift->closed_at->setTimezone('Asia/Bahrain')->format('Y-m-d H:i'));

        Sanctum::actingAs($this->owner);
        $this->getJson("/api/v1/shifts?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonPath('data.0.auto_closed', true);
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
