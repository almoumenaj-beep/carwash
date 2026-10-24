<?php

namespace Tests\Feature;

use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenancyException;
use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantIsolationTest extends TestCase
{
    use RefreshDatabase;

    private Tenant $tenantA;

    private Tenant $tenantB;

    private TenantContext $tenantContext;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenantA = Tenant::factory()->create();
        $this->tenantB = Tenant::factory()->create();
        $this->tenantContext = $this->app->make(TenantContext::class);
    }

    public function test_queries_only_return_records_of_the_current_tenant(): void
    {
        $ownBranch = Branch::factory()->for($this->tenantA)->create();
        Branch::factory()->for($this->tenantB)->create();

        $this->tenantContext->set($this->tenantA);

        $this->assertSame([$ownBranch->id], Branch::query()->pluck('id')->all());
    }

    public function test_a_record_of_another_tenant_cannot_be_found_by_id(): void
    {
        $foreignBranch = Branch::factory()->for($this->tenantB)->create();

        $this->tenantContext->set($this->tenantA);

        $this->assertNull(Branch::find($foreignBranch->id));
    }

    public function test_new_records_are_assigned_to_the_current_tenant(): void
    {
        $this->tenantContext->set($this->tenantA);

        $branch = Branch::create(['name' => 'Main', 'code' => 'MAIN']);

        $this->assertSame($this->tenantA->id, $branch->tenant_id);
    }

    public function test_creating_a_record_for_another_tenant_is_rejected(): void
    {
        $this->tenantContext->set($this->tenantA);

        $this->expectException(TenancyException::class);

        Branch::factory()->for($this->tenantB)->create();
    }

    public function test_creating_a_record_without_any_tenant_is_rejected(): void
    {
        $this->expectException(TenancyException::class);

        Branch::create(['name' => 'Main', 'code' => 'MAIN']);
    }

    public function test_moving_a_record_to_another_tenant_is_rejected(): void
    {
        $this->tenantContext->set($this->tenantA);
        $branch = Branch::factory()->create();

        $this->expectException(TenancyException::class);

        $branch->tenant_id = $this->tenantB->id;
        $branch->save();
    }

    public function test_tenant_data_cannot_be_queried_without_a_current_tenant(): void
    {
        Branch::factory()->for($this->tenantA)->create();

        $this->expectException(TenancyException::class);

        Branch::query()->get();
    }

    public function test_running_as_another_tenant_restores_the_previous_tenant(): void
    {
        $this->tenantContext->set($this->tenantA);

        $tenantIdInside = $this->tenantContext->run($this->tenantB, fn () => $this->tenantContext->id());

        $this->assertSame($this->tenantB->id, $tenantIdInside);
        $this->assertSame($this->tenantA->id, $this->tenantContext->id());
        $this->assertSame($this->tenantA->id, getPermissionsTeamId());
    }
}
