<?php

namespace Tests\Feature;

use App\Domain\Appointments\Models\Appointment;
use App\Domain\Catalog\Models\Service;
use App\Domain\Crm\Models\Customer;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class CustomerPageTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private string $slug;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->slug = $this->tenant->slug;
    }

    /**
     * A day ahead with opening hours, and a start time an hour after opening.
     *
     * @return array{0: CarbonImmutable, 1: string}
     */
    private function bookableSlot(): array
    {
        $day = CarbonImmutable::now($this->tenant->timezone)->addDay()->startOfDay();

        while ($this->branch->openingWindow($day) === null) {
            $day = $day->addDay();
        }

        $start = $this->branch->openingWindow($day)[0]->addHour();

        return [$day, $start->format('Y-m-d\TH:i')];
    }

    public function test_the_page_shows_services_their_prices_and_active_packages_instead_of_offers(): void
    {
        $this->inTenant(function (): void {
            $package = Service::factory()->create([
                'name' => 'Full care package',
                'description' => 'Wash and wax',
                'is_package' => true,
            ]);
            $package->packageItems()->attach([$this->wash->id => ['sort_order' => 0]]);
        });

        $this->get("/w/{$this->slug}")
            ->assertOk()
            ->assertSee($this->tenant->name)
            ->assertSee('Exterior wash')
            ->assertSee('Full care package')
            ->assertDontSee('Offers');
    }

    public function test_an_unknown_slug_is_not_found(): void
    {
        $this->get('/w/no-such-car-wash')->assertNotFound();
    }

    public function test_a_customer_books_a_visit_and_a_real_appointment_is_created(): void
    {
        [, $startsAt] = $this->bookableSlot();

        $this->post("/w/{$this->slug}/bookings", [
            'customer_name' => 'Sara',
            'customer_phone' => '3999 2222',
            'branch_id' => $this->branch->id,
            'vehicle_size_id' => $this->sedan->id,
            'service_id' => $this->wash->id,
            'starts_at' => $startsAt,
        ])
            ->assertRedirect("/w/{$this->slug}")
            ->assertSessionHas('booked');

        $appointment = $this->inTenant(fn () => Appointment::query()->sole());
        // A customer booking themselves waits as pending until reception confirms it.
        $this->assertSame('pending', $appointment->status->value);
        $this->assertSame('Sara', $appointment->customer_name);
        $this->assertSame('+97339992222', $appointment->customer_phone);
        $this->assertSame($this->branch->id, $appointment->branch_id);
        $this->assertSame(2000, $appointment->estimated_total);
        $this->assertSame(1, count($appointment->items));
        $this->assertSame($this->wash->id, $appointment->items[0]['service_id']);
        $this->assertSame(1, $appointment->items[0]['quantity']);
        $this->assertNull($appointment->created_by);
        // The customer is registered just as if reception had booked it, so the wash knows them on arrival.
        $this->assertSame(1, $this->inTenant(fn () => Customer::query()->where('phone', '+97339992222')->count()));
    }

    public function test_booking_with_missing_details_bounces_back_with_errors(): void
    {
        $this->post("/w/{$this->slug}/bookings", [
            'customer_name' => '',
            'customer_phone' => '',
            'branch_id' => $this->branch->id,
            'starts_at' => 'not-a-time',
        ])->assertSessionHasErrors(['customer_name', 'customer_phone', 'starts_at']);
    }

    public function test_the_slots_endpoint_lists_the_free_start_times_of_a_day(): void
    {
        [$day] = $this->bookableSlot();

        $this->getJson("/w/{$this->slug}/slots?branch_id={$this->branch->id}&date={$day->toDateString()}")
            ->assertOk()
            ->assertJsonStructure(['data' => [['starts_at', 'time', 'free']]]);
    }
}
