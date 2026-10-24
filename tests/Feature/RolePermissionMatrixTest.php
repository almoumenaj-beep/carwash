<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

/**
 * Checks every default role against the whole catalog through the gate, so a change to the
 * matrix, the provisioning or the owner bypass shows up as a named role and permission.
 */
class RolePermissionMatrixTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    /**
     * @return array<string, array{DefaultRole}>
     */
    public static function defaultRoles(): array
    {
        return collect(DefaultRole::cases())
            ->mapWithKeys(fn (DefaultRole $role) => [$role->value => [$role]])
            ->all();
    }

    #[DataProvider('defaultRoles')]
    public function test_default_role_grants_exactly_its_permissions(DefaultRole $defaultRole): void
    {
        $tenant = $this->createTenantWithRoles();
        $user = $this->createStaff($tenant, $defaultRole);
        $this->enterTenant($tenant);

        $granted = $defaultRole === DefaultRole::Owner ? Permission::cases() : $defaultRole->permissions();

        foreach (Permission::cases() as $permission) {
            $this->assertSame(
                in_array($permission, $granted, true),
                $user->can($permission->value),
                "{$defaultRole->value} → {$permission->value}",
            );
        }
    }

    public function test_permissions_only_apply_in_the_tenant_that_granted_them(): void
    {
        $tenantA = $this->createTenantWithRoles();
        $tenantB = $this->createTenantWithRoles();
        $owner = $this->createStaff($tenantA, DefaultRole::Owner);

        $this->enterTenant($tenantB);

        $this->assertFalse($owner->isOwner());
        $this->assertFalse($owner->can(Permission::OrdersView->value));
    }
}
