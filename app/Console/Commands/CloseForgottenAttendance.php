<?php

namespace App\Console\Commands;

use App\Domain\Platform\Models\Tenant;
use App\Domain\Staff\Actions\CloseForgottenAttendance as CloseForgottenAttendanceAction;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Clocks out, at their branch's closing time, every tenant's staff who forgot to. Scheduled every
 * fifteen minutes; safe to run at any time, since only attendance past its closing time is closed.
 */
#[Signature('attendance:close-forgotten')]
#[Description('Clock out staff who forgot to, at their branch\'s closing time')]
class CloseForgottenAttendance extends Command
{
    public function handle(CloseForgottenAttendanceAction $closeForgottenAttendance): int
    {
        Tenant::query()->orderBy('created_at')->each(function (Tenant $tenant) use ($closeForgottenAttendance): void {
            $closed = $closeForgottenAttendance->handle($tenant);

            if ($closed > 0) {
                $this->components->info("{$tenant->name}: {$closed} staff clocked out automatically");
            }
        });

        return self::SUCCESS;
    }
}
