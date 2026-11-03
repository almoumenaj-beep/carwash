<?php

namespace App\Console\Commands;

use App\Domain\Appointments\Actions\MarkLateNoShows as MarkLateNoShowsAction;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Marks as no-shows the bookings whose car has not come within each car wash's grace time. Scheduled every
 * five minutes; safe to run at any time.
 */
#[Signature('appointments:mark-no-shows')]
#[Description('Mark bookings as no-shows once the grace time after them has passed')]
class MarkLateNoShows extends Command
{
    public function handle(MarkLateNoShowsAction $markLateNoShows): int
    {
        Tenant::query()->orderBy('created_at')->each(function (Tenant $tenant) use ($markLateNoShows): void {
            $marked = $markLateNoShows->handle($tenant);

            if ($marked > 0) {
                $this->components->info("{$tenant->name}: {$marked} booking(s) marked as no-shows");
            }
        });

        return self::SUCCESS;
    }
}
