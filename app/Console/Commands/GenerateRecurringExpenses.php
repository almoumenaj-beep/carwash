<?php

namespace App\Console\Commands;

use App\Domain\Expenses\Actions\GenerateDueRecurringExpenses;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Records every tenant's recurring expenses that have fallen due as owed expenses. Scheduled daily;
 * safe to run more often, since each schedule moves on once recorded.
 */
#[Signature('expenses:generate-recurring')]
#[Description('Record recurring expenses that have fallen due')]
class GenerateRecurringExpenses extends Command
{
    public function handle(GenerateDueRecurringExpenses $generateDueRecurringExpenses): int
    {
        Tenant::query()->orderBy('created_at')->each(function (Tenant $tenant) use ($generateDueRecurringExpenses): void {
            $created = $generateDueRecurringExpenses->handle($tenant);

            if ($created > 0) {
                $this->components->info("{$tenant->name}: {$created} recurring expense(s) recorded");
            }
        });

        return self::SUCCESS;
    }
}
