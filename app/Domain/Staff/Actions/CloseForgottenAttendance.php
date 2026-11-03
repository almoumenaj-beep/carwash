<?php

namespace App\Domain\Staff\Actions;

use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Domain\Staff\Models\AttendanceLog;
use Carbon\CarbonImmutable;

/**
 * Clocks out the staff of a tenant who forgot to, once their branch has closed: the attendance ends at
 * the closing time of the opening hours they clocked in during (or, when they clocked in outside opening
 * hours, at that day's closing time still to come, else at the end of that day), marked as automatic.
 */
class CloseForgottenAttendance
{
    public function __construct(private TenantContext $tenantContext) {}

    /**
     * @return int How many staff were clocked out.
     */
    public function handle(Tenant $tenant): int
    {
        return $this->tenantContext->run($tenant, function () use ($tenant): int {
            $now = CarbonImmutable::now($tenant->timezone);
            $closed = 0;

            foreach (AttendanceLog::query()->whereNull('clock_out_at')->with('branch')->get() as $log) {
                $closesAt = $this->closingTime($log, $tenant->timezone);
                if ($closesAt->gt($now)) {
                    continue;
                }

                $log->forceFill(['clock_out_at' => $closesAt->utc(), 'auto_clocked_out' => true])->save();
                $closed++;
            }

            return $closed;
        });
    }

    /**
     * When the branch closed after the staff member clocked in.
     */
    public function closingTime(AttendanceLog $log, string $timezone): CarbonImmutable
    {
        $clockIn = CarbonImmutable::parse($log->clock_in_at)->setTimezone($timezone);
        $windows = array_filter([$log->branch->openingWindow($clockIn->subDay()), $log->branch->openingWindow($clockIn)]);

        foreach ($windows as [, $closes]) {
            if ($closes->gt($clockIn)) {
                return $closes;
            }
        }

        return $clockIn->startOfDay()->addDay();
    }
}
