<?php

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;

/**
 * Gives a tenant the usual vehicle sizes, named in its language. Safe to run again:
 * a tenant that already has sizes keeps its own list.
 */
class ProvisionDefaultCatalog
{
    /**
     * @var array<string, list<string>>
     */
    private const DEFAULT_SIZES = [
        'ar' => ['صغيرة', 'سيدان', 'دفع رباعي (SUV)', 'فان / شاحنة'],
        'en' => ['Small', 'Sedan', 'SUV', 'Van / Truck'],
    ];

    public function __construct(private TenantContext $tenantContext) {}

    public function handle(Tenant $tenant): void
    {
        $this->tenantContext->run($tenant, function () use ($tenant): void {
            if (VehicleSize::query()->exists()) {
                return;
            }

            $names = self::DEFAULT_SIZES[$tenant->locale] ?? self::DEFAULT_SIZES['en'];

            // tenant_id is set explicitly because seeders run without model events.
            foreach ($names as $order => $name) {
                (new VehicleSize(['name' => $name, 'sort_order' => $order]))->forceFill(['tenant_id' => $tenant->id])->save();
            }
        });
    }
}
