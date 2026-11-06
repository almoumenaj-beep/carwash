<?php

namespace App\Domain\Appointments\Actions;

use App\Domain\Appointments\Enums\AppointmentStatus;
use App\Domain\Appointments\Models\Appointment;
use App\Domain\Appointments\Support\AppointmentSchedule;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Crm\Actions\SaveCustomer;
use App\Domain\Crm\Actions\SaveVehicle;
use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Orders\Support\OrderPricing;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Books a car in at a branch, or changes a booking: a registered car, or a customer's phone (linked to
 * the customer when the number is known, else registering a new one, with a new car too when the plate
 * is given) with the car's plate and size when known. The services are priced and timed as at check-in,
 * and the visit must fit the branch's hours and free bays. Bookings at a branch are made one at a time
 * so two counters never take the last place together.
 */
class BookAppointment
{
    /**
     * The shortest visit booked, so services without a set time still hold a place.
     */
    public const MINIMUM_MINUTES = 15;

    public function __construct(
        private OrderPricing $pricing,
        private AppointmentSchedule $schedule,
        private AuditTrail $auditTrail,
        private SaveCustomer $saveCustomer,
        private SaveVehicle $saveVehicle,
    ) {}

    /**
     * @param  array{branch_id: string, starts_at: string, vehicle_id?: ?string, plate_number?: ?string, vehicle_size_id?: ?string, customer_phone?: ?string, customer_name?: ?string, items: list<array{service_id: string, quantity?: int}>, notes?: ?string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, array $data, ?Appointment $appointment = null): Appointment
    {
        $branch = Branch::query()->findOrFail($data['branch_id']);
        $vehicle = match (true) {
            isset($data['vehicle_id']) => Vehicle::query()->findOrFail($data['vehicle_id']),
            filled($data['plate_number'] ?? null) => Vehicle::query()->where('plate_number', $data['plate_number'])->first(),
            default => null,
        };
        $customer = $vehicle?->customer
            ?? (filled($data['customer_phone'] ?? null) ? Customer::query()->where('phone', $data['customer_phone'])->first() : null);

        $sizeId = $data['vehicle_size_id'] ?? $vehicle?->vehicle_size_id;
        $size = $sizeId === null ? null : VehicleSize::query()->find($sizeId);
        $priced = $this->pricing->price($branch, $size, $data['items']);

        $start = CarbonImmutable::createFromFormat('Y-m-d\TH:i', $data['starts_at'], $actor->tenant->timezone)->startOfMinute();
        $end = $start->addMinutes(max($priced['minutes'], self::MINIMUM_MINUTES));

        return DB::transaction(function () use ($actor, $data, $appointment, $branch, $vehicle, $customer, $size, $priced, $start, $end): Appointment {
            Branch::query()->whereKey($branch->id)->lockForUpdate()->first();
            $this->schedule->ensureBookable($branch, $start, $end, $appointment?->id);

            // The first time a customer is booked by phone, register them (and their car, if its plate is given)
            // just as a walk-in is registered at check-in.
            if ($customer === null && filled($data['customer_phone'] ?? null)) {
                $customer = $this->saveCustomer->create($actor, ['phone' => $data['customer_phone'], 'name' => $data['customer_name'] ?? null]);
            } elseif ($customer !== null && blank($customer->name) && filled($data['customer_name'] ?? null)) {
                $this->saveCustomer->update($actor, $customer, ['name' => $data['customer_name']]);
            }

            if ($vehicle === null && $customer !== null && filled($data['plate_number'] ?? null)) {
                $vehicle = $this->saveVehicle->create($actor, $customer, ['plate_number' => $data['plate_number'], 'vehicle_size_id' => $size?->id]);
            }

            $isNew = $appointment === null;
            $appointment ??= new Appointment;
            // A booking moved to another time needs confirming again.
            if (! $isNew && ! $appointment->starts_at->equalTo($start)) {
                $appointment->status = AppointmentStatus::Booked;
            }
            $appointment->forceFill([
                'branch_id' => $branch->id,
                'customer_id' => $customer?->id,
                'vehicle_id' => $vehicle?->id,
                'customer_name' => $data['customer_name'] ?? $customer?->name,
                'customer_phone' => $customer?->phone ?? $data['customer_phone'] ?? null,
                'plate_number' => $vehicle?->plate_number ?? $data['plate_number'] ?? null,
                'vehicle_size_id' => $size?->id,
                'items' => array_map(fn (array $item) => ['service_id' => $item['service_id'], 'quantity' => (int) ($item['quantity'] ?? 1)], $data['items']),
                'estimated_total' => $priced['subtotal'],
                'starts_at' => $start->utc(),
                'ends_at' => $end->utc(),
                'notes' => $data['notes'] ?? null,
                'created_by' => $appointment->created_by ?? $actor->id,
            ])->save();

            $this->auditTrail->record($isNew ? 'appointment.booked' : 'appointment.changed', $appointment, $actor, $isNew ? 'Appointment booked' : 'Appointment changed', [
                'starts_at' => $start->toIso8601String(),
            ]);

            return $appointment;
        });
    }
}
