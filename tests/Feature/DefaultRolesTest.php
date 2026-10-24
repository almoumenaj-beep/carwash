<?php

namespace Tests\Feature;

use App\Domain\Identity\Actions\ProvisionDefaultRoles;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class DefaultRolesTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    public function test_every_default_role_is_created_for_the_tenant(): void
    {
        $tenant = $this->createTenantWithRoles();

        $this->assertEqualsCanonicalizing(
            array_column(DefaultRole::cases(), 'value'),
            Role::query()->where('tenant_id', $tenant->id)->pluck('key')->all(),
        );
    }

    public function test_default_roles_start_with_their_catalog_permissions(): void
    {
        $tenant = $this->createTenantWithRoles();

        $this->assertEqualsCanonicalizing(
            [Permission::OrdersView->value, Permission::OrdersUpdateStatus->value],
            $this->defaultRoleOf($tenant, DefaultRole::Washer)->permissions->pluck('name')->all(),
        );
    }

    public function test_provisioning_again_keeps_the_owners_customisations(): void
    {
        $tenant = $this->createTenantWithRoles();
        $cashier = $this->defaultRoleOf($tenant, DefaultRole::Cashier);
        $cashier->revokePermissionTo(Permission::PosDiscount->value);
        $cashier->update(['name' => 'Front Desk']);

        $this->app->make(ProvisionDefaultRoles::class)->handle($tenant);

        $cashier->refresh();
        $this->assertSame('Front Desk', $cashier->name);
        $this->assertFalse($cashier->hasPermissionTo(Permission::PosDiscount->value));
        $this->assertSame(count(DefaultRole::cases()), Role::query()->where('tenant_id', $tenant->id)->count());
    }

    public function test_each_tenant_gets_its_own_roles(): void
    {
        $tenantA = $this->createTenantWithRoles();
        $tenantB = $this->createTenantWithRoles();

        $this->assertNotSame(
            $this->defaultRoleOf($tenantA, DefaultRole::Owner)->id,
            $this->defaultRoleOf($tenantB, DefaultRole::Owner)->id,
        );
    }
}
