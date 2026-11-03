<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Domain\Staff\Actions\ClockAttendance;
use App\Domain\Staff\Models\AttendanceLog;
use App\Http\Controllers\Controller;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * Attendance: every staff member clocks themselves in at a branch they work in and out again; managers
 * with employees.view see a branch's day.
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
     * @return array<string, mixed>
     */
    private function present(AttendanceLog $log): array
    {
        $end = $log->clock_out_at ?? now();

        return [
            'id' => $log->id,
            'user' => ['id' => $log->user->id, 'name' => $log->user->name],
            'branch' => ['id' => $log->branch->id, 'name' => $log->branch->name],
            'clock_in_at' => $log->clock_in_at->toIso8601String(),
            'clock_out_at' => $log->clock_out_at?->toIso8601String(),
            'minutes' => (int) $log->clock_in_at->diffInMinutes($end),
        ];
    }
}
