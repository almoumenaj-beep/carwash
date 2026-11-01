<?php

namespace Tests\Concerns;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServicePrice;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;

/**
 * A ready-to-use car wash for work order tests: two branches with bays, sedan/SUV sizes,
 * a wash priced per size, an add-on priced once, and a registered customer with a sedan.
 */
trait BuildsCarWash
{
    use InteractsWithTenants;

    protected Tenant $tenant;

    protected Branch $branch;

    protected Branch $otherBranch;

    protected Bay $bay;

    protected VehicleSize $sedan;

    protected VehicleSize $suv;

    /** Exterior wash: sedan 2.000, SUV 2.500 BHD. */
    protected Service $wash;

    /** Air freshener: 0.500 BHD for every size. */
    protected Service $freshener;

    protected Customer $customer;

    protected Vehicle $vehicle;

    protected User $cashier;

    protected User $washer;

    protected function buildCarWash(): void
    {
        $this->tenant = $this->createTenantWithRoles();

        $this->inTenant(function (): void {
            $this->branch = Branch::factory()->create(['code' => 'MAIN']);
            $this->otherBranch = Branch::factory()->create(['code' => 'SEEF']);
            $this->bay = Bay::factory()->for($this->branch)->create(['name' => 'Bay 1']);
            $this->sedan = VehicleSize::factory()->create(['name' => 'Sedan']);
            $this->suv = VehicleSize::factory()->create(['name' => 'SUV']);

            $this->wash = Service::factory()->create(['name' => 'Exterior wash', 'duration_minutes' => 15]);
            ServicePrice::factory()->for($this->wash)->create(['vehicle_size_id' => $this->sedan->id, 'price' => 2000]);
            ServicePrice::factory()->for($this->wash)->create(['vehicle_size_id' => $this->suv->id, 'price' => 2500]);

            $this->freshener = Service::factory()->addon()->create(['name' => 'Air freshener', 'duration_minutes' => 2]);
            ServicePrice::factory()->for($this->freshener)->create(['price' => 500]);

            $this->customer = Customer::factory()->create();
            $this->vehicle = Vehicle::factory()->for($this->customer)->create(['plate_number' => '12345', 'vehicle_size_id' => $this->sedan->id]);
        });

        $this->cashier = $this->createStaff($this->tenant, DefaultRole::Cashier, [$this->branch]);
        $this->washer = $this->createStaff($this->tenant, DefaultRole::Washer, [$this->branch]);
    }

    /**
     * @template TReturn
     *
     * @param  callable(): TReturn  $callback
     * @return TReturn
     */
    protected function inTenant(callable $callback): mixed
    {
        return $this->app->make(TenantContext::class)->run($this->tenant, $callback);
    }

    /**
     * Checks the registered sedan in for an exterior wash, as the cashier unless told otherwise.
     *
     * @param  array<string, mixed>  $overrides
     */
    protected function checkIn(array $overrides = [], ?User $as = null): TestResponse
    {
        Sanctum::actingAs($as ?? $this->cashier);

        return $this->postJson('/api/v1/orders', [
            'branch_id' => $this->branch->id,
            'vehicle_id' => $this->vehicle->id,
            'items' => [['service_id' => $this->wash->id]],
            ...$overrides,
        ]);
    }

    /**
     * @param  array<string, mixed>  $extra
     */
    protected function moveTo(string $orderId, string $status, User $as, array $extra = []): TestResponse
    {
        Sanctum::actingAs($as);

        return $this->postJson("/api/v1/orders/{$orderId}/status", ['status' => $status, ...$extra]);
    }
}
