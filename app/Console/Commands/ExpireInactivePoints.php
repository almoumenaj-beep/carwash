<?php

namespace App\Console\Commands;

use App\Domain\Platform\Models\Tenant;
use App\Domain\Sales\Actions\ExpireInactivePoints as ExpireInactivePointsAction;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Clears the points of customers inactive for the period each car wash set. Scheduled daily; safe to run at
 * any time.
 */
#[Signature('points:expire')]
#[Description('Clear the points of customers inactive for the period each car wash set')]
class ExpireInactivePoints extends Command
{
    public function handle(ExpireInactivePointsAction $expireInactivePoints): int
    {
        Tenant::query()->orderBy('created_at')->each(function (Tenant $tenant) use ($expireInactivePoints): void {
            $expired = $expireInactivePoints->handle($tenant);

            if ($expired > 0) {
                $this->components->info("{$tenant->name}: points expired for {$expired} customers");
            }
        });

        return self::SUCCESS;
    }
}
