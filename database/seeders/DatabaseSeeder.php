<?php

namespace Database\Seeders;

use App\Domain\Identity\Actions\ProvisionDefaultRoles;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Models\Bay;
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

        $mainBranch = Branch::factory()->for($tenant)->create(['name' => 'Main Branch', 'code' => 'MAIN']);

        foreach (['Bay 1', 'Bay 2', 'Detailing'] as $order => $bayName) {
            Bay::factory()->for($mainBranch)->create(['name' => $bayName, 'sort_order' => $order]);
        }

        $owner = User::factory()->forTenant($tenant)->withPin('1234')->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'phone' => '0500000001',
        ]);

        $cashier = User::factory()->forTenant($tenant)->withPin('1111')->create([
            'name' => 'Demo Cashier',
            'email' => 'cashier@example.com',
            'phone' => '0500000002',
        ]);

        $tenantContext->run($tenant, function () use ($tenant, $owner, $cashier, $mainBranch): void {
            $owner->assignRole($this->defaultRole($tenant, DefaultRole::Owner));
            $cashier->assignRole($this->defaultRole($tenant, DefaultRole::Cashier));
            $cashier->branches()->attach($mainBranch);
        });

        $this->call(DemoCatalogSeeder::class);
    }

    private function defaultRole(Tenant $tenant, DefaultRole $defaultRole): Role
    {
        return Role::query()->ofTenant($tenant->id)->where('key', $defaultRole->value)->firstOrFail();
    }
}
