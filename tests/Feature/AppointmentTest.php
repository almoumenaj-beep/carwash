<?php

namespace Tests\Feature;

use App\Domain\Appointments\Models\Appointment;
use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Bay;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class AppointmentTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $receptionist;

    protected function setUp(): void
    {
        parent::setUp();

        // Tuesday 3 November 2026, 10:00 in Bahrain; the branch is open 08:00–22:00 with one bay.
        $this->travelTo(CarbonImmutable::parse('2026-11-03 10:00', 'Asia/Bahrain'));
        $this->buildCarWash();
        $this->receptionist = $this->createStaff($this->tenant, DefaultRole::Receptionist, [$this->branch]);
    }

    /**
     * A walk-in sedan booked for a wash (15 minutes) by phone, tomorrow at 10:00 unless told otherwise.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function book(array $overrides = [], ?User $as = null): TestResponse
    {
        Sanctum::actingAs($as ?? $this->receptionist);

        return $this->postJson('/api/v1/appointments', [
            'branch_id' => $this->branch->id,
            'starts_at' => '2026-11-04T10:00',
            'customer_phone' => '3999 1111',
            'customer_name' => 'Hassan',
            'plate_number' => '55-777',
            'vehicle_size_id' => $this->sedan->id,
            'items' => [['service_id' => $this->wash->id]],
            ...$overrides,
        ]);
    }

    public function test_a_receptionist_books_a_car_by_phone_and_sees_it_on_the_day(): void
    {
        $this->book(['notes' => 'Prefers the shade'])
            ->assertCreated()
            ->assertJsonPath('data.starts_at', '2026-11-04T10:00:00+03:00')
            ->assertJsonPath('data.ends_at', '2026-11-04T10:15:00+03:00')
            ->assertJsonPath('data.status', 'booked')
            ->assertJsonPath('data.customer_phone', '+97339991111')
            ->assertJsonPath('data.customer.name', 'Hassan')
            ->assertJsonPath('data.plate_number', '55777')
            ->assertJsonPath('data.items.0.name', 'Exterior wash')
            ->assertJsonPath('data.estimated_total', 2000);

        $this->getJson("/api/v1/appointments?branch_id={$this->branch->id}&date=2026-11-04")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.customer_name', 'Hassan');
        $this->getJson("/api/v1/appointments?branch_id={$this->branch->id}")->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/customers')->assertJsonPath('data.0.name', 'Hassan')->assertJsonPath('data.0.vehicles.0.plate_number', '55777');
        $this->assertDatabaseHas('activity_log', ['event' => 'appointment.booked', 'tenant_id' => $this->tenant->id]);
        $this->assertDatabaseHas('activity_log', ['event' => 'customer.created', 'tenant_id' => $this->tenant->id]);
    }

    public function test_booking_the_same_new_phone_twice_registers_the_customer_only_once(): void
    {
        $this->book()->assertCreated();
        $this->book(['starts_at' => '2026-11-04T11:00', 'plate_number' => '66-888'])->assertCreated();

        $this->assertSame(1, $this->inTenant(fn () => Customer::query()->where('phone', '+97339991111')->count()));
        $vehicles = $this->getJson('/api/v1/customers')->assertOk()->json('data.0.vehicles');
        $this->assertCount(2, $vehicles);
    }

    public function test_a_known_phone_or_car_is_linked_to_its_customer(): void
    {
        $this->book(['customer_phone' => $this->customer->phone, 'plate_number' => null])
            ->assertCreated()
            ->assertJsonPath('data.customer.id', $this->customer->id);

        $this->book(['starts_at' => '2026-11-04T11:00', 'vehicle_id' => $this->vehicle->id, 'customer_phone' => null, 'vehicle_size_id' => null])
            ->assertCreated()
            ->assertJsonPath('data.customer.id', $this->customer->id)
            ->assertJsonPath('data.plate_number', '12345')
            ->assertJsonPath('data.vehicle_size.id', $this->sedan->id);
    }

    public function test_a_time_holds_as_many_cars_as_the_branch_has_bays(): void
    {
        $this->book()->assertCreated();
        $this->book(['starts_at' => '2026-11-04T10:00'])->assertUnprocessable()->assertJsonValidationErrors('starts_at');
        $this->book(['starts_at' => '2026-11-04T10:15'])->assertCreated();

        $this->inTenant(fn () => Bay::factory()->for($this->branch)->create(['name' => 'Bay 2']));
        $this->book(['starts_at' => '2026-11-04T10:00'])->assertCreated();
    }

    public function test_a_booking_fits_the_opening_hours_and_the_future(): void
    {
        $this->book(['starts_at' => '2026-11-04T21:50'])->assertUnprocessable()->assertJsonValidationErrors('starts_at');
        $this->book(['starts_at' => '2026-11-04T07:30'])->assertUnprocessable()->assertJsonValidationErrors('starts_at');
        $this->book(['starts_at' => '2026-11-03T09:00'])->assertUnprocessable()->assertJsonValidationErrors('starts_at');

        $this->branch->update(['opening_hours' => [...$this->branch->opening_hours, 'fri' => null]]);
        $this->book(['starts_at' => '2026-11-06T10:00'])->assertUnprocessable()->assertJsonValidationErrors('starts_at');

        $this->book(['customer_phone' => null])->assertUnprocessable()->assertJsonValidationErrors('customer_phone');
    }

    public function test_free_times_leave_out_the_past_and_full_times(): void
    {
        $this->book()->assertCreated();

        $tomorrow = $this->getJson("/api/v1/appointments/slots?branch_id={$this->branch->id}&date=2026-11-04&minutes=15")
            ->assertOk()
            ->assertJsonPath('meta.capacity', 1)
            ->assertJsonPath('data.0', ['starts_at' => '2026-11-04T08:00', 'time' => '08:00', 'free' => 1]);
        $times = array_column($tomorrow->json('data'), 'time');
        $this->assertNotContains('10:00', $times);
        $this->assertContains('10:30', $times);
        $this->assertSame('21:30', end($times));

        $this->getJson("/api/v1/appointments/slots?branch_id={$this->branch->id}&date=2026-11-03&minutes=15")
            ->assertOk()
            ->assertJsonPath('data.0.time', '10:30');
    }

    public function test_a_booked_car_is_checked_in_once_and_joins_the_queue(): void
    {
        $appointmentId = $this->book()->json('data.id');

        $checkIn = [
            'branch_id' => $this->branch->id,
            'plate_number' => '55-777',
            'vehicle_size_id' => $this->sedan->id,
            'customer_phone' => '39991111',
            'customer_name' => 'Hassan',
            'items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]],
            'staff_ids' => [$this->washer->id],
        ];
        $orderId = $this->postJson("/api/v1/appointments/{$appointmentId}/check-in", $checkIn)
            ->assertCreated()
            ->assertJsonPath('data.status', 'waiting')
            ->json('data.id');

        $this->getJson("/api/v1/appointments?branch_id={$this->branch->id}&date=2026-11-04")
            ->assertJsonPath('data.0.status', 'checked_in')
            ->assertJsonPath('data.0.order.id', $orderId);
        $this->postJson("/api/v1/appointments/{$appointmentId}/check-in", $checkIn)->assertUnprocessable();
        $this->assertSame(1, $this->inTenant(fn () => Order::query()->count()));
    }

    public function test_cancelled_and_no_show_bookings_free_their_time(): void
    {
        $appointmentId = $this->book()->json('data.id');

        $this->postJson("/api/v1/appointments/{$appointmentId}/no-show")->assertUnprocessable();
        $this->postJson("/api/v1/appointments/{$appointmentId}/cancel", ['reason' => 'Car broke down'])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.cancel_reason', 'Car broke down');
        $this->patchJson("/api/v1/appointments/{$appointmentId}", ['branch_id' => $this->branch->id, 'starts_at' => '2026-11-04T12:00', 'customer_phone' => '39991111', 'items' => [['service_id' => $this->wash->id]]])
            ->assertUnprocessable();

        $secondId = $this->book()->assertCreated()->json('data.id');
        $this->travelTo(CarbonImmutable::parse('2026-11-04 10:30', 'Asia/Bahrain'));
        $this->postJson("/api/v1/appointments/{$secondId}/no-show")->assertOk()->assertJsonPath('data.status', 'no_show');
    }

    public function test_a_booking_is_moved_without_counting_against_itself(): void
    {
        $appointmentId = $this->book()->json('data.id');

        $this->patchJson("/api/v1/appointments/{$appointmentId}", [
            'branch_id' => $this->branch->id,
            'starts_at' => '2026-11-04T10:00',
            'customer_phone' => '39991111',
            'vehicle_size_id' => $this->sedan->id,
            'items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]],
        ])
            ->assertOk()
            ->assertJsonPath('data.ends_at', '2026-11-04T10:17:00+03:00')
            ->assertJsonPath('data.estimated_total', 2500);
        $this->assertSame(1, $this->inTenant(fn () => Appointment::query()->count()));
    }

    public function test_a_confirmed_booking_keeps_its_place_until_it_is_moved(): void
    {
        $appointmentId = $this->book()->json('data.id');

        Sanctum::actingAs($this->cashier);
        $this->postJson("/api/v1/appointments/{$appointmentId}/confirm")->assertForbidden();

        Sanctum::actingAs($this->receptionist);
        $this->postJson("/api/v1/appointments/{$appointmentId}/confirm")->assertOk()->assertJsonPath('data.status', 'confirmed');
        $this->postJson("/api/v1/appointments/{$appointmentId}/confirm")->assertUnprocessable();
        $this->book()->assertUnprocessable()->assertJsonValidationErrors('starts_at');

        $moved = [
            'branch_id' => $this->branch->id,
            'customer_phone' => '39991111',
            'vehicle_size_id' => $this->sedan->id,
            'items' => [['service_id' => $this->wash->id]],
        ];
        $this->patchJson("/api/v1/appointments/{$appointmentId}", [...$moved, 'starts_at' => '2026-11-04T10:00', 'notes' => 'Same time'])
            ->assertJsonPath('data.status', 'confirmed');
        $this->patchJson("/api/v1/appointments/{$appointmentId}", [...$moved, 'starts_at' => '2026-11-04T12:00'])
            ->assertJsonPath('data.status', 'booked');

        $this->postJson("/api/v1/appointments/{$appointmentId}/confirm")->assertOk();
        $this->postJson("/api/v1/appointments/{$appointmentId}/check-in", [
            'branch_id' => $this->branch->id,
            'plate_number' => '55-777',
            'vehicle_size_id' => $this->sedan->id,
            'items' => [['service_id' => $this->wash->id]],
            'staff_ids' => [$this->washer->id],
        ])->assertCreated();
    }

    public function test_a_booked_car_checked_in_at_the_counter_closes_its_booking(): void
    {
        $byPlateId = $this->book()->json('data.id');
        $byCarId = $this->book(['starts_at' => '2026-11-04T11:00', 'vehicle_id' => $this->vehicle->id, 'customer_phone' => null])->json('data.id');
        $otherId = $this->book(['starts_at' => '2026-11-04T12:00', 'customer_phone' => '39992222', 'plate_number' => '99-999'])->json('data.id');

        $this->travelTo(CarbonImmutable::parse('2026-11-04 10:05', 'Asia/Bahrain'));
        $orderId = $this->checkIn(['vehicle_id' => null, 'plate_number' => '55777', 'vehicle_size_id' => $this->sedan->id])
            ->assertCreated()
            ->assertJsonPath('meta.appointment.id', $byPlateId)
            ->json('data.id');
        $this->checkIn()->assertCreated()->assertJsonPath('meta.appointment.id', $byCarId);
        $this->checkIn(['vehicle_id' => null, 'plate_number' => '11-111', 'vehicle_size_id' => $this->sedan->id])->assertCreated()->assertJsonPath('meta.appointment', null);

        $statuses = $this->inTenant(fn () => Appointment::query()->pluck('status', 'id')->map->value);
        $this->assertSame(['checked_in', 'checked_in', 'booked'], [$statuses[$byPlateId], $statuses[$byCarId], $statuses[$otherId]]);
        $this->assertSame($orderId, $this->inTenant(fn () => Appointment::query()->find($byPlateId)->order_id));
    }

    public function test_a_car_arriving_after_the_grace_time_turns_the_no_show_into_arrived(): void
    {
        $this->tenant->update(['appointment_grace_minutes' => 20]);
        $appointmentId = $this->book()->json('data.id');

        $this->travelTo(CarbonImmutable::parse('2026-11-04 11:00', 'Asia/Bahrain'));
        $this->artisan('appointments:mark-no-shows')->assertSuccessful();
        $this->assertSame('no_show', $this->inTenant(fn () => Appointment::query()->find($appointmentId)->status->value));

        $this->checkIn(['vehicle_id' => null, 'plate_number' => '55777', 'vehicle_size_id' => $this->sedan->id])
            ->assertCreated()
            ->assertJsonPath('meta.appointment.id', $appointmentId);
        $this->assertSame('checked_in', $this->inTenant(fn () => Appointment::query()->find($appointmentId)->status->value));
    }

    public function test_another_car_of_the_customer_leaves_a_booking_for_a_named_car_open(): void
    {
        $forThisCar = $this->book(['vehicle_id' => $this->vehicle->id, 'customer_phone' => null])->json('data.id');
        $byPhoneOnly = $this->book(['starts_at' => '2026-11-04T11:00', 'customer_phone' => $this->customer->phone, 'plate_number' => null])->json('data.id');

        $this->travelTo(CarbonImmutable::parse('2026-11-04 10:50', 'Asia/Bahrain'));
        $otherCar = $this->inTenant(fn () => Vehicle::factory()->for($this->customer)->create(['plate_number' => '77777', 'vehicle_size_id' => $this->sedan->id]));

        $this->checkIn(['vehicle_id' => $otherCar->id])->assertCreated()->assertJsonPath('meta.appointment.id', $byPhoneOnly);
        $this->assertSame('booked', $this->inTenant(fn () => Appointment::query()->find($forThisCar)->status->value));
    }

    public function test_a_late_booking_becomes_a_no_show_after_the_grace_time_set(): void
    {
        $this->tenant->update(['appointment_grace_minutes' => 20]);
        $lateId = $this->book()->json('data.id');
        $arrivedId = $this->book(['starts_at' => '2026-11-04T10:15'])->json('data.id');

        $this->travelTo(CarbonImmutable::parse('2026-11-04 10:19', 'Asia/Bahrain'));
        $this->artisan('appointments:mark-no-shows')->assertSuccessful();
        $this->assertSame('booked', $this->inTenant(fn () => Appointment::query()->find($lateId)->status->value));

        $this->travelTo(CarbonImmutable::parse('2026-11-04 10:20', 'Asia/Bahrain'));
        $this->artisan('appointments:mark-no-shows')->assertSuccessful();
        $this->assertSame('no_show', $this->inTenant(fn () => Appointment::query()->find($lateId)->status->value));
        $this->assertSame('booked', $this->inTenant(fn () => Appointment::query()->find($arrivedId)->status->value));

        $this->tenant->update(['appointment_grace_minutes' => null]);
        $this->travelTo(CarbonImmutable::parse('2026-11-04 18:00', 'Asia/Bahrain'));
        $this->artisan('appointments:mark-no-shows')->assertSuccessful();
        $this->assertSame('booked', $this->inTenant(fn () => Appointment::query()->find($arrivedId)->status->value));
    }

    public function test_bookings_are_kept_to_the_staff_and_branch_allowed(): void
    {
        $this->book()->assertCreated();

        Sanctum::actingAs($this->washer);
        $this->getJson("/api/v1/appointments?branch_id={$this->branch->id}")->assertForbidden();

        Sanctum::actingAs($this->cashier);
        $this->getJson("/api/v1/appointments?branch_id={$this->branch->id}&date=2026-11-04")->assertOk()->assertJsonCount(1, 'data');
        $this->book(as: $this->cashier)->assertForbidden();

        $elsewhere = $this->createStaff($this->tenant, DefaultRole::Receptionist, [$this->otherBranch]);
        Sanctum::actingAs($elsewhere);
        $this->getJson("/api/v1/appointments?branch_id={$this->branch->id}")->assertForbidden();
        $this->book(as: $elsewhere)->assertForbidden();
    }
}
