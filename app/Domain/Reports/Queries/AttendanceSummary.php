<?php

namespace App\Domain\Reports\Queries;

use App\Domain\Platform\Models\Branch;
use App\Domain\Staff\Models\AttendanceLog;
use Carbon\CarbonImmutable;

/**
 * Attendance at a branch over a period, per staff member: the days they came, their minutes at work and how
 * often the system had to clock them out. A record counts on the day it was clocked in, in the car wash's
 * time zone, as in the day's view; someone still at work counts up to now. Nothing here affects pay.
 */
class AttendanceSummary
{
    /**
     * @return array{total_minutes: int, staff: list<array{user: array{id: string, name: string}, days: int, minutes: int, auto_clocked_out: int, records: list<AttendanceLog>}>}
     */
    public function for(Branch $branch, CarbonImmutable $from, CarbonImmutable $to): array
    {
        $logs = AttendanceLog::query()
            ->where('branch_id', $branch->id)
            ->where('clock_in_at', '>=', $from->startOfDay()->utc())
            ->where('clock_in_at', '<', $to->startOfDay()->addDay()->utc())
            ->with(['user', 'branch'])
            ->orderBy('clock_in_at')
            ->get();

        $staff = $logs->groupBy('user_id')
            ->map(fn ($records) => [
                'user' => ['id' => $records->first()->user->id, 'name' => $records->first()->user->name],
                'days' => $records->map(fn (AttendanceLog $log) => $log->clock_in_at->setTimezone($from->getTimezone())->toDateString())->unique()->count(),
                'minutes' => $records->sum(fn (AttendanceLog $log) => $log->minutesWorked()),
                'auto_clocked_out' => $records->where('auto_clocked_out', true)->count(),
                'records' => $records->values()->all(),
            ])
            ->sortByDesc('minutes')
            ->values();

        return ['total_minutes' => $staff->sum('minutes'), 'staff' => $staff->all()];
    }
}
