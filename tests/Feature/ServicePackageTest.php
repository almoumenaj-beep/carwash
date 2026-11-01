<?php

namespace Tests\Feature;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServiceCategory;
use App\Domain\Catalog\Models\ServicePrice;
use App\Domain\Identity\Enums\DefaultRole;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class ServicePackageTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $owner;

    /** Interior clean: 3.000 BHD for every size. */
    private Service $interior;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->interior = $this->inTenant(function (): Service {
            $interior = Service::factory()->create(['name' => 'Interior clean', 'duration_minutes' => 20]);
            ServicePrice::factory()->for($interior)->create(['price' => 3000]);

            return $interior;
        });
    }

    /**
     * Exterior wash + interior clean + air freshener, less the given discount.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function createPackage(array $overrides = []): string
    {
        Sanctum::actingAs($this->owner);

        return $this->postJson('/api/v1/services', [
            'name' => 'VIP',
            'is_package' => true,
            'package_discount_type' => 'percent',
            'package_discount_value' => 2000,
            'package_service_ids' => [$this->wash->id, $this->interior->id, $this->freshener->id],
            ...$overrides,
        ])->assertCreated()->json('data.id');
    }

    public function test_the_owner_builds_a_package_from_existing_services(): void
    {
        $packageId = $this->createPackage();

        $this->getJson("/api/v1/services/{$packageId}")
            ->assertJsonPath('data.is_package', true)
            ->assertJsonPath('data.package_discount_type', 'percent')
            ->assertJsonPath('data.package_discount_value', 2000)
            ->assertJsonPath('data.package_items.0.name', 'Exterior wash')
            ->assertJsonPath('data.package_items.1.name', 'Interior clean')
            ->assertJsonPath('data.prices', []);
    }

    public function test_packages_have_their_own_section_so_they_take_no_category(): void
    {
        $category = $this->inTenant(fn () => ServiceCategory::factory()->create());
        $packageId = $this->createPackage(['service_category_id' => $category->id]);

        $this->getJson("/api/v1/services/{$packageId}")->assertJsonPath('data.service_category_id', null);
    }

    public function test_a_package_needs_two_services_and_cannot_contain_packages(): void
    {
        Sanctum::actingAs($this->owner);
        $package = ['name' => 'Tiny', 'is_package' => true, 'package_discount_type' => 'amount', 'package_discount_value' => 100];

        $this->postJson('/api/v1/services', [...$package, 'package_service_ids' => [$this->wash->id]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('package_service_ids');

        $vip = $this->createPackage();
        $this->postJson('/api/v1/services', [...$package, 'package_service_ids' => [$this->wash->id, $vip]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('package_service_ids');

        $this->postJson('/api/v1/services', [...$package, 'package_discount_type' => 'percent', 'package_discount_value' => 10001, 'package_service_ids' => [$this->wash->id, $this->interior->id]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('package_discount_value');
    }

    public function test_a_package_costs_its_services_for_the_car_less_the_discount(): void
    {
        $percentOff = $this->createPackage();
        $amountOff = $this->createPackage(['name' => 'Saver', 'package_discount_type' => 'amount', 'package_discount_value' => 1000]);

        // Sedan: 2.000 + 3.000 + 0.500 = 5.500; 20% off = 4.400, or 1.000 off = 4.500.
        $this->checkIn(['items' => [['service_id' => $percentOff]]])
            ->assertCreated()
            ->assertJsonPath('data.subtotal', 4400)
            ->assertJsonPath('data.estimated_minutes', 37)
            ->assertJsonPath('data.items.0.is_package', true)
            ->assertJsonPath('data.items.0.unit_price', 4400)
            ->assertJsonPath('data.items.0.components.0.name', 'Exterior wash')
            ->assertJsonCount(3, 'data.items.0.components');
        $this->checkIn(['items' => [['service_id' => $amountOff]]])->assertJsonPath('data.subtotal', 4500);

        // SUV: 2.500 + 3.000 + 0.500 = 6.000; 20% off = 4.800.
        $this->checkIn(['vehicle_id' => null, 'plate_number' => '777', 'vehicle_size_id' => $this->suv->id, 'items' => [['service_id' => $percentOff]]])
            ->assertJsonPath('data.subtotal', 4800);
    }

    public function test_a_package_follows_price_changes_of_its_services(): void
    {
        $packageId = $this->createPackage();
        $this->inTenant(fn () => ServicePrice::query()->where('service_id', $this->interior->id)->update(['price' => 4000]));

        // 2.000 + 4.000 + 0.500 = 6.500; 20% off = 5.200.
        $this->checkIn(['items' => [['service_id' => $packageId]]])->assertJsonPath('data.subtotal', 5200);
    }

    public function test_a_package_is_unavailable_for_a_size_one_of_its_services_has_no_price_for(): void
    {
        $packageId = $this->createPackage();

        $this->checkIn(['vehicle_id' => null, 'plate_number' => '777', 'vehicle_size_id' => null, 'items' => [['service_id' => $packageId]]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items.0.service_id');
    }

    public function test_each_service_of_a_package_is_inspected_and_the_invoice_shows_the_package(): void
    {
        $packageId = $this->createPackage();
        $order = $this->checkIn(['items' => [['service_id' => $packageId], ['service_id' => $this->freshener->id]]]);
        $orderId = $order->json('data.id');
        $this->moveTo($orderId, 'in_progress', $this->washer);
        $this->moveTo($orderId, 'qc', $this->washer);

        $this->passInspection($orderId, $this->washer)
            ->assertOk()
            ->assertJsonCount(4, 'data.quality_checks.0.results')
            ->assertJsonPath('data.quality_checks.0.results.0.name', 'Exterior wash');

        $this->pay($orderId)->assertCreated()->assertJsonPath('data.invoice.total', 4900);
        $this->assertDatabaseCount('invoice_lines', 2);
        $this->assertDatabaseHas('invoice_lines', ['name' => 'VIP', 'line_total' => 4400]);
    }

    public function test_a_service_inside_a_package_cannot_be_deleted(): void
    {
        $this->createPackage();

        $this->deleteJson("/api/v1/services/{$this->interior->id}")
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['service' => 'This service is part of a package. Remove it from the package first.']);
    }

    public function test_turning_a_package_back_into_a_service_drops_its_contents(): void
    {
        $packageId = $this->createPackage();

        $this->patchJson("/api/v1/services/{$packageId}", ['is_package' => false])
            ->assertOk()
            ->assertJsonPath('data.package_items', [])
            ->assertJsonPath('data.package_discount_type', null);
    }
}
