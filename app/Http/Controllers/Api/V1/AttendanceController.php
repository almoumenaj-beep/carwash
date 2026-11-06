<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Domain\Reports\Queries\AttendanceSummary;
use App\Domain\Staff\Actions\ClockAttendance;
use App\Domain\Staff\Models\AttendanceLog;
use App\Http\Controllers\Controller;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

/**
 * Attendance: every staff member clocks themselves in at a branch they work in and out again; managers
 * with employees.view see a branch's day, or a summary per staff member over a period.
 */
class AttendanceController extends Controller
{
    /**
     * The user's own open record, or `data: null` when they are not clocked in.
     */
    public function me(Request $request): JsonResponse
    {
        $log = AttendanceLog::openFor($request->user());

        return response()->json(['data' => $log === null ? null : $this->present($log->load(['user', 'branch']))]);
    }

    public function clockIn(Request $request, ClockAttendance $clockAttendance): JsonResponse
    {
        $request->validate(['branch_id' => ['required', 'uuid']]);
        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        $log = $clockAttendance->in($request->user(), $branch);

        return response()->json(['data' => $this->present($log->load(['user', 'branch']))], 201);
    }

    public function clockOut(Request $request, ClockAttendance $clockAttendance): JsonResponse
    {
        $log = $clockAttendance->out($request->user());

        return response()->json(['data' => $this->present($log->load(['user', 'branch']))]);
    }

    /**
     * Everyone who clocked in at a branch on a day (default today, in the car wash's time zone).
     */
    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::EmployeesView->value);
        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ]);

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        $timezone = $request->user()->tenant->timezone;
        $day = $request->filled('date')
            ? CarbonImmutable::createFromFormat('Y-m-d', $request->input('date'), $timezone)->startOfDay()
            : CarbonImmutable::now($timezone)->startOfDay();

        $logs = AttendanceLog::query()
            ->where('branch_id', $branch->id)
            ->where('clock_in_at', '>=', $day->utc())
            ->where('clock_in_at', '<', $day->addDay()->utc())
            ->with(['user', 'branch'])
            ->orderBy('clock_in_at')
            ->get();

        return response()->json(['data' => $logs->map($this->present(...))]);
    }

    /**
     * A branch's attendance per staff member over a period (`from`-`to`, default this month so far, at most a year).
     */
    public function summary(Request $request, AttendanceSummary $attendanceSummary): JsonResponse
    {
        Gate::authorize(Permission::EmployeesView->value);
        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'from' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'to' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'after_or_equal:from'],
        ]);

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        $timezone = $request->user()->tenant->timezone;
        $today = CarbonImmutable::now($timezone)->startOfDay();
        $from = $request->filled('from') ? CarbonImmutable::createFromFormat('Y-m-d', $request->input('from'), $timezone)->startOfDay() : $today->startOfMonth();
        $to = $request->filled('to') ? CarbonImmutable::createFromFormat('Y-m-d', $request->input('to'), $timezone)->startOfDay() : $today;

        if ($from->addYear()->lte($to)) {
            throw ValidationException::withMessages(['to' => __('The report covers a year at most.')]);
        }

        $summary = $attendanceSummary->for($branch, $from, $to);

        return response()->json(['data' => [
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
            'total_minutes' => $summary['total_minutes'],
            'staff' => array_map(fn (array $member) => [
                ...$member,
                'records' => array_map($this->present(...), $member['records']),
            ], $summary['staff']),
        ]]);
    }

    /**
     * @return array<string, mixed>
     */
    private function present(AttendanceLog $log): array
    {
        return [
            'id' => $log->id,
            'user' => ['id' => $log->user->id, 'name' => $log->user->name],
            'branch' => ['id' => $log->branch->id, 'name' => $log->branch->name],
            'clock_in_at' => $log->clock_in_at->toIso8601String(),
            'clock_out_at' => $log->clock_out_at?->toIso8601String(),
            'minutes' => $log->minutesWorked(),
            'auto_clocked_out' => $log->auto_clocked_out,
        ];
    }
}
