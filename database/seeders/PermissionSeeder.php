<?php

namespace Database\Seeders;

use App\Domain\Identity\Actions\SyncPermissionCatalog;
use Illuminate\Database\Seeder;

/**
 * Syncs the permission catalog. Safe to run on every deployment.
 */
class PermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(SyncPermissionCatalog $syncPermissionCatalog): void
    {
        $syncPermissionCatalog->handle();
    }
}
