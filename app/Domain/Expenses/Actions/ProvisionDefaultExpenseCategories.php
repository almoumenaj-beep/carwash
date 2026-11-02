<?php

namespace App\Domain\Expenses\Actions;

use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;

/**
 * Gives a tenant the usual expense categories, named in its language. Safe to run again: a tenant
 * that already has categories keeps its own list.
 */
class ProvisionDefaultExpenseCategories
{
    /**
     * @var array<string, list<string>>
     */
    private const DEFAULT_CATEGORIES = [
        'ar' => ['إيجار', 'كهرباء وماء', 'مواد تنظيف', 'صيانة ومعدات', 'رواتب وأجور', 'نقل ووقود', 'تسويق', 'أخرى'],
        'en' => ['Rent', 'Electricity and water', 'Cleaning supplies', 'Maintenance and equipment', 'Wages', 'Transport and fuel', 'Marketing', 'Other'],
    ];

    public function __construct(private TenantContext $tenantContext) {}

    public function handle(Tenant $tenant): void
    {
        $this->tenantContext->run($tenant, function () use ($tenant): void {
            if (ExpenseCategory::query()->exists()) {
                return;
            }

            $names = self::DEFAULT_CATEGORIES[$tenant->locale] ?? self::DEFAULT_CATEGORIES['en'];

            // tenant_id is set explicitly because seeders run without model events.
            foreach ($names as $order => $name) {
                (new ExpenseCategory(['name' => $name, 'sort_order' => $order]))->forceFill(['tenant_id' => $tenant->id])->save();
            }
        });
    }
}
