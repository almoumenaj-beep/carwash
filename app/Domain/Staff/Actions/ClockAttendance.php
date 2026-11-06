<?php

namespace App\Domain\Staff\Actions;

use App\Domain\Platform\Models\Branch;
use App\Domain\Sales\Models\CashShift;
use App\Domain\Staff\Models\AttendanceLog;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * A staff member clocking in at a branch they work in, and out again when they leave. They cannot clock
 * out with an open cash shift at that branch; it must be closed, with the drawer counted, first.
 */
class ClockAttendance
{
    /**
     * @throws ValidationException
     */
    public function in(User $user, Branch $branch): AttendanceLog
    {
        return DB::transaction(function () use ($user, $branch): AttendanceLog {
            User::query()->whereKey($user->id)->lockForUpdate()->first();

            if (AttendanceLog::openFor($user) !== null) {
                throw ValidationException::withMessages(['attendance' => __('You are already clocked in.')]);
            }

            $log = new AttendanceLog;
            $log->forceFill(['user_id' => $user->id, 'branch_id' => $branch->id, 'clock_in_at' => now()])->save();

            return $log;
        });
    }

    /**
     * @throws ValidationException
     */
    public function out(User $user): AttendanceLog
    {
        $log = AttendanceLog::openFor($user)
            ?? throw ValidationException::withMessages(['attendance' => __('You are not clocked in.')]);

        if (CashShift::openFor($user, $log->branch) !== null) {
            throw ValidationException::withMessages(['shift' => __('Close your cashier before clocking out.')]);
        }

        $log->forceFill(['clock_out_at' => now()])->save();

        return $log;
    }
}
