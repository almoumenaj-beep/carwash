<?php

namespace Database\Seeders;

use App\Domain\Identity\Actions\ProvisionDefaultRoles;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(ProvisionDefaultRoles $provisionDefaultRoles, TenantContext $tenantContext): void
    {
        $this->call(PermissionSeeder::class);

        $tenant = Tenant::factory()->create(['name' => 'Demo Car Wash', 'slug' => 'demo']);

        $provisionDefaultRoles->handle($tenant);

        Branch::factory()->for($tenant)->create(['name' => 'Main Branch', 'code' => 'MAIN']);

        $owner = User::factory()->forTenant($tenant)->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);

        $tenantContext->run($tenant, fn () => $owner->assignRole(
            Role::query()->where('tenant_id', $tenant->id)->where('key', DefaultRole::Owner->value)->firstOrFail(),
        ));
    }
}
