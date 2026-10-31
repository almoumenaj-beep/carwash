<?php

namespace App\Console\Commands;

use App\Domain\Catalog\Actions\ProvisionDefaultCatalog;
use App\Domain\Identity\Actions\ProvisionDefaultRoles;
use App\Domain\Identity\Actions\SyncPermissionCatalog;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Brings every tenant up to date with the defaults new tenants get (permission catalog,
 * default roles, vehicle sizes). Idempotent: existing data and customisations are kept.
 * Run after deployments that add defaults.
 */
#[Signature('tenants:provision-defaults')]
#[Description('Add missing default roles and catalog entries to every tenant')]
class ProvisionTenantDefaults extends Command
{
    public function handle(
        SyncPermissionCatalog $syncPermissionCatalog,
        ProvisionDefaultRoles $provisionDefaultRoles,
        ProvisionDefaultCatalog $provisionDefaultCatalog,
    ): int {
        $syncPermissionCatalog->handle();

        Tenant::query()->orderBy('created_at')->each(function (Tenant $tenant) use ($provisionDefaultRoles, $provisionDefaultCatalog): void {
            $provisionDefaultRoles->handle($tenant);
            $provisionDefaultCatalog->handle($tenant);

            $this->components->info("Provisioned {$tenant->name}");
        });

        return self::SUCCESS;
    }
}
