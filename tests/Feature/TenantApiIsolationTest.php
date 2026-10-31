<?php

namespace Tests\Feature;

use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Proves the API pipeline sets the tenant from the authenticated user before route model binding.
 * Uses probe routes so the guarantee holds independently of any feature endpoint.
 */
class TenantApiIsolationTest extends TestCase
{
    use RefreshDatabase;

    private Tenant $tenantA;

    private Tenant $tenantB;

    protected function setUp(): void
    {
        parent::setUp();

        Route::middleware(['api', 'auth:sanctum'])->prefix('api/testing')->group(function () {
            Route::get('branches', fn () => ['ids' => Branch::query()->pluck('id')]);
            Route::get('branches/{branch}', fn (Branch $branch) => ['id' => $branch->id]);
            Route::get('permission-team', fn () => ['team' => getPermissionsTeamId()]);
        });

        $this->tenantA = Tenant::factory()->create();
        $this->tenantB = Tenant::factory()->create();
    }

    public function test_listing_returns_only_records_of_the_users_tenant(): void
    {
        $ownBranch = Branch::factory()->for($this->tenantA)->create();
        Branch::factory()->for($this->tenantB)->create();
        Sanctum::actingAs(User::factory()->forTenant($this->tenantA)->create());

        $this->getJson('/api/testing/branches')
            ->assertOk()
            ->assertExactJson(['ids' => [$ownBranch->id]]);
    }

    public function test_own_record_is_resolved_by_route_binding(): void
    {
        $ownBranch = Branch::factory()->for($this->tenantA)->create();
        Sanctum::actingAs(User::factory()->forTenant($this->tenantA)->create());

        $this->getJson("/api/testing/branches/{$ownBranch->id}")
            ->assertOk()
            ->assertJsonPath('id', $ownBranch->id);
    }

    public function test_record_of_another_tenant_is_not_found(): void
    {
        $foreignBranch = Branch::factory()->for($this->tenantB)->create();
        Sanctum::actingAs(User::factory()->forTenant($this->tenantA)->create());

        $this->getJson("/api/testing/branches/{$foreignBranch->id}")->assertNotFound();
    }

    public function test_permission_team_follows_the_users_tenant(): void
    {
        Sanctum::actingAs(User::factory()->forTenant($this->tenantA)->create());

        $this->getJson('/api/testing/permission-team')
            ->assertOk()
            ->assertJsonPath('team', $this->tenantA->id);
    }

    public function test_users_of_a_suspended_tenant_are_forbidden(): void
    {
        $suspendedTenant = Tenant::factory()->suspended()->create();
        Sanctum::actingAs(User::factory()->forTenant($suspendedTenant)->create());

        $this->getJson('/api/testing/branches')
            ->assertForbidden()
            ->assertJsonPath('detail', 'This car wash account is suspended.');
    }

    public function test_users_without_a_tenant_are_forbidden(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/testing/branches')
            ->assertForbidden()
            ->assertJsonPath('detail', 'This account is not linked to a car wash.');
    }

    public function test_guests_are_unauthorized(): void
    {
        $this->getJson('/api/testing/branches')->assertUnauthorized();

        $this->assertNull($this->app->make(TenantContext::class)->id());
    }
}
