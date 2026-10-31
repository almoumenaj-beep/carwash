<?php

namespace Tests\Feature;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServicePrice;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class ServicePriceResolutionTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Service $service;

    private VehicleSize $sedan;

    private VehicleSize $suv;

    private Branch $riffa;

    private Branch $seef;

    protected function setUp(): void
    {
        parent::setUp();

        $tenant = Tenant::factory()->create();
        $this->enterTenant($tenant);
        $this->service = Service::factory()->create();
        $this->sedan = VehicleSize::factory()->create();
        $this->suv = VehicleSize::factory()->create();
        $this->riffa = Branch::factory()->create();
        $this->seef = Branch::factory()->create();
    }

    private function price(?VehicleSize $size, ?Branch $branch, int $price): void
    {
        ServicePrice::factory()->for($this->service)->create([
            'vehicle_size_id' => $size?->id,
            'branch_id' => $branch?->id,
            'price' => $price,
        ]);
    }

    public function test_the_most_specific_price_wins(): void
    {
        $this->price(null, null, 1000);
        $this->price(null, $this->riffa, 1200);
        $this->price($this->suv, null, 3000);
        $this->price($this->suv, $this->riffa, 3500);
        $service = $this->service->load('prices');

        $this->assertSame(3500, $service->priceFor($this->suv, $this->riffa), 'size at this branch');
        $this->assertSame(3000, $service->priceFor($this->suv, $this->seef), 'size anywhere');
        $this->assertSame(1200, $service->priceFor($this->sedan, $this->riffa), 'every size at this branch');
        $this->assertSame(1000, $service->priceFor($this->sedan, $this->seef), 'every size anywhere');
        $this->assertSame(3000, $service->priceFor($this->suv), 'no branch given');
    }

    public function test_an_unpriced_combination_has_no_price(): void
    {
        $this->price($this->suv, null, 3000);

        $this->assertNull($this->service->load('prices')->priceFor($this->sedan, $this->riffa));
    }
}
