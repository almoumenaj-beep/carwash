<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Domain\Sales\Models\CashShift;
use Carbon\CarbonImmutable;

/**
 * Closes the cash shifts a cashier forgot to, once their branch has closed: the drawer is "closed" with
 * the expected cash as the count, since nobody counted it, and marked automatic so it still needs a real
 * count. A shift closes at the closing time of the opening hours it was opened during (or, when it was
 * opened outside opening hours, at that day's closing time still to come, else at the end of that day).
 */
class CloseForgottenCashShifts
{
    public function __construct(private TenantContext $tenantContext, private AuditTrail $auditTrail) {}

    /**
     * @return int How many shifts were closed.
     */
    public function handle(Tenant $tenant): int
    {
        return $this->tenantContext->run($tenant, function () use ($tenant): int {
            $now = CarbonImmutable::now($tenant->timezone);
            $closed = 0;

            foreach (CashShift::query()->whereNull('closed_at')->with('branch')->get() as $shift) {
                $closesAt = $this->closingTime($shift, $tenant->timezone);
                if ($closesAt->gt($now)) {
                    continue;
                }

                $expected = $shift->expectedCash();
                $shift->forceFill([
                    'closed_at' => $closesAt->utc(),
                    'expected_cash' => $expected,
                    'counted_cash' => $expected,
                    'variance' => 0,
                    'close_note' => __('Closed automatically at closing time; the drawer still needs to be counted.'),
                    'auto_closed' => true,
                ])->save();

                $this->auditTrail->record('cash_shift.auto_closed', $shift, null, 'Shift closed automatically', [
                    'expected_cash' => $expected,
                ]);
                $closed++;
            }

            return $closed;
        });
    }

    /**
     * When the branch closed after the shift opened.
     */
    private function closingTime(CashShift $shift, string $timezone): CarbonImmutable
    {
        $openedAt = CarbonImmutable::parse($shift->opened_at)->setTimezone($timezone);
        $windows = array_filter([$shift->branch->openingWindow($openedAt->subDay()), $shift->branch->openingWindow($openedAt)]);

        foreach ($windows as [, $closes]) {
            if ($closes->gt($openedAt)) {
                return $closes;
            }
        }

        return $openedAt->startOfDay()->addDay();
    }
}
