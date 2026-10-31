<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class RoleApiTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
    }

    public function test_guests_cannot_list_roles(): void
    {
        $this->getJson('/api/v1/roles')->assertUnauthorized();
    }

    public function test_owner_lists_only_the_roles_of_their_tenant(): void
    {
        $this->createTenantWithRoles();
        Sanctum::actingAs($this->owner);

        $this->getJson('/api/v1/roles')
            ->assertOk()
            ->assertJsonCount(count(DefaultRole::cases()), 'data')
            ->assertJsonPath('data.0.key', DefaultRole::Owner->value)
            ->assertJsonPath('data.0.is_owner_role', true)
            ->assertJsonPath('data.0.users_count', 1);
    }

    public function test_staff_without_roles_or_users_permission_cannot_list_roles(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Cashier));

        $this->getJson('/api/v1/roles')->assertForbidden();
    }

    public function test_permission_catalog_is_grouped_by_module_and_translated(): void
    {
        Sanctum::actingAs($this->owner);

        $response = $this->withHeader('Accept-Language', 'ar')
            ->getJson('/api/v1/permissions')
            ->assertOk()
            ->assertJsonPath('data.0.module', 'orders')
            ->assertJsonPath('data.0.label', 'أوامر العمل')
            ->assertJsonPath('data.0.permissions.0.name', Permission::OrdersView->value)
            ->assertJsonPath('data.0.permissions.0.label', 'عرض أوامر العمل');

        $this->assertSame(count(Permission::cases()), collect($response->json('data'))->sum(fn (array $module) => count($module['permissions'])));
    }

    public function test_owner_creates_a_custom_role(): void
    {
        Sanctum::actingAs($this->owner);

        $response = $this->postJson('/api/v1/roles', [
            'name' => 'Night Supervisor',
            'permissions' => [Permission::PosCloseShift->value, Permission::OrdersView->value],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.name', 'Night Supervisor')
            ->assertJsonPath('data.key', null)
            ->assertJsonPath('data.permissions', [Permission::OrdersView->value, Permission::PosCloseShift->value]);

        $this->assertDatabaseHas('roles', ['id' => $response->json('data.id'), 'tenant_id' => $this->tenant->id]);
        $this->assertDatabaseHas('activity_log', [
            'log_name' => AuditTrail::LOG_NAME,
            'event' => 'role.created',
            'tenant_id' => $this->tenant->id,
            'causer_id' => $this->owner->id,
        ]);
    }

    public function test_role_names_are_unique_within_a_tenant(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/roles', ['name' => DefaultRole::Cashier->displayName(), 'permissions' => []])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('name');
    }

    public function test_permissions_outside_the_catalog_are_rejected(): void
    {
        Sanctum::actingAs($this->owner);

        $this->postJson('/api/v1/roles', ['name' => 'Supervisor', 'permissions' => ['orders.fly']])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('permissions.0');
    }

    public function test_staff_cannot_grant_permissions_they_do_not_have(): void
    {
        Sanctum::actingAs($this->createStaffWithPermissions($this->tenant, [Permission::RolesManage, Permission::OrdersView]));

        $this->postJson('/api/v1/roles', ['name' => 'Payroll Clerk', 'permissions' => [Permission::PayrollRun->value]])
            ->assertForbidden()
            ->assertJsonPath('message', 'You cannot grant or revoke permissions you do not have: payroll.run');
        $this->assertDatabaseMissing('roles', ['name' => 'Payroll Clerk']);

        $this->postJson('/api/v1/roles', ['name' => 'Viewer', 'permissions' => [Permission::OrdersView->value]])
            ->assertCreated();
    }

    public function test_owner_replaces_a_roles_permissions_and_the_change_is_audited(): void
    {
        Sanctum::actingAs($this->owner);
        $cashierRole = $this->defaultRoleOf($this->tenant, DefaultRole::Cashier);

        $this->putJson("/api/v1/roles/{$cashierRole->id}/permissions", ['permissions' => [Permission::OrdersView->value]])
            ->assertOk()
            ->assertJsonPath('data.permissions', [Permission::OrdersView->value]);

        $this->assertSame([Permission::OrdersView->value], $cashierRole->fresh()->permissions->pluck('name')->all());
        $this->assertDatabaseHas('activity_log', [
            'event' => 'role.permissions_synced',
            'tenant_id' => $this->tenant->id,
            'subject_id' => $cashierRole->id,
            'causer_id' => $this->owner->id,
        ]);
    }

    public function test_owner_renames_a_role(): void
    {
        Sanctum::actingAs($this->owner);
        $washerRole = $this->defaultRoleOf($this->tenant, DefaultRole::Washer);

        $this->patchJson("/api/v1/roles/{$washerRole->id}", ['name' => 'Detailer'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Detailer')
            ->assertJsonPath('data.label', 'Detailer')
            ->assertJsonPath('data.key', DefaultRole::Washer->value);
    }

    public function test_owner_role_cannot_be_changed(): void
    {
        Sanctum::actingAs($this->owner);
        $ownerRole = $this->defaultRoleOf($this->tenant, DefaultRole::Owner);

        $this->putJson("/api/v1/roles/{$ownerRole->id}/permissions", ['permissions' => []])->assertForbidden();
        $this->patchJson("/api/v1/roles/{$ownerRole->id}", ['name' => 'Boss'])->assertForbidden();
        $this->deleteJson("/api/v1/roles/{$ownerRole->id}")->assertForbidden();
    }

    public function test_role_of_another_tenant_is_not_found(): void
    {
        $foreignRole = $this->defaultRoleOf($this->createTenantWithRoles(), DefaultRole::Cashier);
        Sanctum::actingAs($this->owner);

        $this->getJson("/api/v1/roles/{$foreignRole->id}")->assertNotFound();
        $this->putJson("/api/v1/roles/{$foreignRole->id}/permissions", ['permissions' => []])->assertNotFound();
    }

    public function test_role_held_by_staff_cannot_be_deleted(): void
    {
        $this->createStaff($this->tenant, DefaultRole::Cashier);
        Sanctum::actingAs($this->owner);
        $cashierRole = $this->defaultRoleOf($this->tenant, DefaultRole::Cashier);

        $this->deleteJson("/api/v1/roles/{$cashierRole->id}")
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');
        $this->assertModelExists($cashierRole);
    }

    public function test_unused_role_is_deleted(): void
    {
        $unusedRole = Role::create(['name' => 'Temporary', 'tenant_id' => $this->tenant->id]);
        Sanctum::actingAs($this->owner);

        $this->deleteJson("/api/v1/roles/{$unusedRole->id}")->assertNoContent();

        $this->assertModelMissing($unusedRole);
    }
}
