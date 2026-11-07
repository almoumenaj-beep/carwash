<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Crm\Models\Customer;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Domain\Sales\Enums\PointTransactionType;
use App\Domain\Sales\Support\PointsLedger;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * Clears the points of customers with no earning or spending for as many months as the owner set. Nothing
 * expires when the owner set no period, or while the points system is off.
 */
class ExpireInactivePoints
{
    public function __construct(private TenantContext $tenantContext, private PointsLedger $pointsLedger) {}

    /**
     * @return int How many customers lost their points.
     */
    public function handle(Tenant $tenant): int
    {
        if (! $tenant->points_enabled || $tenant->points_expiry_months === null) {
            return 0;
        }

        return $this->tenantContext->run($tenant, function () use ($tenant): int {
            $cutoff = CarbonImmutable::now()->subMonths($tenant->points_expiry_months);
            $expired = 0;

            $customers = Customer::query()
                ->where('points_balance', '>', 0)
                ->whereDoesntHave('pointTransactions', fn ($query) => $query->where('created_at', '>=', $cutoff))
                ->get();

            foreach ($customers as $customer) {
                DB::transaction(function () use ($customer): void {
                    $locked = Customer::query()->whereKey($customer->id)->lockForUpdate()->firstOrFail();
                    $this->pointsLedger->move($locked, PointTransactionType::Expired, -$locked->points_balance);
                });
                $expired++;
            }

            return $expired;
        });
    }
}
