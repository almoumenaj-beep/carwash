<?php

namespace Database\Seeders;

use App\Domain\Catalog\Actions\ProvisionDefaultCatalog;
use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServiceCategory;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Seeder;

/**
 * Sample menu for the demo car wash (prices in fils, VAT included). Skips a tenant that already
 * has services, so it can run on an existing database: php artisan db:seed --class=DemoCatalogSeeder
 */
class DemoCatalogSeeder extends Seeder
{
    /**
     * Service name => [category, minutes, add-on, prices per default size or one price for all sizes].
     *
     * @var array<string, array{string, int, bool, list<int>|int}>
     */
    private const SERVICES = [
        'غسيل خارجي' => ['غسيل', 15, false, [1500, 2000, 2500, 3500]],
        'غسيل داخلي وخارجي' => ['غسيل', 40, false, [3000, 3500, 4500, 6000]],
        'تلميع كامل' => ['تلميع', 120, false, [15000, 18000, 22000, 28000]],
        'معطّر' => ['إضافات', 2, true, 500],
        'تلميع الإطارات' => ['إضافات', 5, true, 1000],
    ];

    public function run(ProvisionDefaultCatalog $provisionDefaultCatalog, TenantContext $tenantContext): void
    {
        $tenant = Tenant::query()->where('slug', 'demo')->first();
        if ($tenant === null) {
            return;
        }

        $provisionDefaultCatalog->handle($tenant);

        $tenantContext->run($tenant, function () use ($tenant): void {
            if (Service::query()->exists()) {
                return;
            }

            $sizes = VehicleSize::query()->orderBy('sort_order')->pluck('id')->all();
            $categoryIds = [];

            // tenant_id is set explicitly throughout because DatabaseSeeder runs without model events.
            foreach (self::SERVICES as $name => [$categoryName, $minutes, $isAddon, $prices]) {
                $categoryIds[$categoryName] ??= $this->createCategory($tenant, $categoryName, count($categoryIds));

                $service = new Service([
                    'service_category_id' => $categoryIds[$categoryName],
                    'name' => $name,
                    'duration_minutes' => $minutes,
                    'is_addon' => $isAddon,
                ]);
                $service->forceFill(['tenant_id' => $tenant->id])->save();

                $rows = is_int($prices)
                    ? [[null, $prices]]
                    : array_map(null, array_slice($sizes, 0, count($prices)), $prices);

                foreach ($rows as [$sizeId, $price]) {
                    $service->prices()->make(['vehicle_size_id' => $sizeId, 'price' => $price])
                        ->forceFill(['tenant_id' => $tenant->id])
                        ->save();
                }
            }
        });
    }

    private function createCategory(Tenant $tenant, string $name, int $sortOrder): string
    {
        $category = new ServiceCategory(['name' => $name, 'sort_order' => $sortOrder]);
        $category->forceFill(['tenant_id' => $tenant->id])->save();

        return $category->id;
    }
}
