<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Domain\Sales\Models\CashShift;
use Carbon\CarbonImmutable;

/**
 * Closes the cash shifts a cashier forgot to, once their branch has closed. Nobody counted the drawer, so
 * no count or variance is recorded: the shift waits for the owner or a manager to enter the real count. A
 * shift closes at the closing time of the opening hours it was opened during (or, when it was opened outside
 * opening hours, at that day's closing time still to come, else at the end of that day), and never before
 * its last payment, in case this did not run for a while.
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
                $lastPayment = $shift->payments()->max('received_at');
                $closedAt = $lastPayment === null ? $closesAt->utc() : $closesAt->utc()->max(CarbonImmutable::parse($lastPayment, 'UTC'));

                $shift->forceFill([
                    'closed_at' => $closedAt,
                    'expected_cash' => $expected,
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
