<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use Database\Seeders\PermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\TestWith;
use Spatie\Permission\Models\Permission as PermissionModel;
use Tests\TestCase;

class PermissionCatalogTest extends TestCase
{
    use RefreshDatabase;

    public function test_sync_creates_every_catalog_permission(): void
    {
        $this->seed(PermissionSeeder::class);

        $this->assertEqualsCanonicalizing(Permission::values(), PermissionModel::query()->pluck('name')->all());
    }

    public function test_sync_is_idempotent(): void
    {
        $this->seed(PermissionSeeder::class);
        $this->seed(PermissionSeeder::class);

        $this->assertSame(count(Permission::cases()), PermissionModel::query()->count());
    }

    public function test_sync_removes_permissions_dropped_from_the_catalog(): void
    {
        $legacyPermission = PermissionModel::create(['name' => 'legacy.feature']);
        $role = Role::create(['name' => 'Custom']);
        $role->givePermissionTo($legacyPermission);

        $this->seed(PermissionSeeder::class);

        $this->assertDatabaseMissing('permissions', ['name' => 'legacy.feature']);
        $this->assertDatabaseMissing('role_has_permissions', ['role_id' => $role->id]);
    }

    #[TestWith(['ar'])]
    #[TestWith(['en'])]
    public function test_every_permission_and_module_is_translated(string $locale): void
    {
        foreach (Permission::cases() as $permission) {
            $this->assertTrue(trans()->has("permissions.{$permission->value}", $locale, false), "{$locale}: {$permission->value}");
            $this->assertTrue(trans()->has("permissions.modules.{$permission->module()}", $locale, false), "{$locale}: module {$permission->module()}");
        }
    }

    public function test_every_permission_belongs_to_a_module(): void
    {
        foreach (Permission::cases() as $permission) {
            $this->assertMatchesRegularExpression('/^[a-z]+\.[a-z_]+$/', $permission->value);
            $this->assertSame(strstr($permission->value, '.', true), $permission->module());
        }
    }
}
