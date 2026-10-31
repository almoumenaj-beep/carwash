<?php

namespace Tests\Concerns;

use App\Domain\Identity\Actions\ProvisionDefaultRoles;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Database\Seeders\PermissionSeeder;

trait InteractsWithTenants
{
    /**
     * Create a tenant with the permission catalog and its default roles in place.
     */
    protected function createTenantWithRoles(): Tenant
    {
        $this->seed(PermissionSeeder::class);

        $tenant = Tenant::factory()->create();

        $this->app->make(ProvisionDefaultRoles::class)->handle($tenant);

        return $tenant;
    }

    protected function enterTenant(Tenant $tenant): void
    {
        $this->app->make(TenantContext::class)->set($tenant);
    }

    protected function defaultRoleOf(Tenant $tenant, DefaultRole $defaultRole): Role
    {
        return Role::query()->where('tenant_id', $tenant->id)->where('key', $defaultRole->value)->firstOrFail();
    }

    /**
     * Create a staff member holding a custom role with exactly the given permissions.
     *
     * @param  list<Permission>  $permissions
     */
    protected function createStaffWithPermissions(Tenant $tenant, array $permissions, bool $allBranches = true): User
    {
        $role = Role::create(['name' => 'Custom '.fake()->unique()->word(), 'tenant_id' => $tenant->id]);
        $role->syncPermissions(array_map(fn (Permission $permission) => $permission->value, $permissions));

        $user = User::factory()->forTenant($tenant)->create(['all_branches' => $allBranches]);

        $this->app->make(TenantContext::class)->run($tenant, fn () => $user->assignRole($role));

        return $user;
    }

    /**
     * @param  list<Branch>  $branches
     */
    protected function createStaff(Tenant $tenant, DefaultRole $defaultRole, array $branches = [], bool $allBranches = false): User
    {
        $user = User::factory()->forTenant($tenant)->create(['all_branches' => $allBranches]);

        $this->app->make(TenantContext::class)->run($tenant, function () use ($user, $tenant, $defaultRole, $branches): void {
            $user->assignRole($this->defaultRoleOf($tenant, $defaultRole));
            $user->branches()->attach(array_map(fn (Branch $branch) => $branch->id, $branches));
        });

        return $user;
    }
}
