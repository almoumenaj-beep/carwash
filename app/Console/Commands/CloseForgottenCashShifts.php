<?php

namespace App\Console\Commands;

use App\Domain\Platform\Models\Tenant;
use App\Domain\Sales\Actions\CloseForgottenCashShifts as CloseForgottenCashShiftsAction;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Closes, at their branch's closing time, every tenant's cash shifts a cashier forgot to close. Scheduled
 * every fifteen minutes; safe to run at any time, since only a shift past its closing time is closed.
 */
#[Signature('cash-shifts:close-forgotten')]
#[Description("Close cash shifts their cashiers forgot to, at their branch's closing time")]
class CloseForgottenCashShifts extends Command
{
    public function handle(CloseForgottenCashShiftsAction $closeForgottenCashShifts): int
    {
        Tenant::query()->orderBy('created_at')->each(function (Tenant $tenant) use ($closeForgottenCashShifts): void {
            $closed = $closeForgottenCashShifts->handle($tenant);

            if ($closed > 0) {
                $this->components->info("{$tenant->name}: {$closed} cash shift(s) closed automatically");
            }
        });

        return self::SUCCESS;
    }
}
