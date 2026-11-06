<?php

namespace App\Domain\Appointments\Actions;

use App\Domain\Appointments\Enums\AppointmentStatus;
use App\Domain\Appointments\Models\Appointment;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Carbon\CarbonImmutable;

/**
 * A car checked in at the counter may have been booked: today's booking at that branch for the same car
 * (registered car or plate), or for the same customer when the booking names no car, is marked as arrived
 * with the order, so it neither runs late nor stays a no-show. A booking still waiting wins over one
 * already marked as a no-show, then the one closest to now. Another car of the same customer does not
 * close a booking made for a named car.
 */
class MatchBookingOnArrival
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function handle(User $actor, Order $order): ?Appointment
    {
        $now = CarbonImmutable::now($actor->tenant->timezone);
        $appointment = Appointment::query()
            ->where('branch_id', $order->branch_id)
            ->whereIn('status', [...AppointmentStatus::open(), AppointmentStatus::NoShow])
            ->where('starts_at', '>=', $now->startOfDay()->utc())
            ->where('starts_at', '<', $now->startOfDay()->addDay()->utc())
            ->get()
            ->filter(fn (Appointment $appointment) => $this->isFor($appointment, $order))
            ->sortBy(fn (Appointment $appointment) => [
                $appointment->isOpen() ? 0 : 1,
                abs($appointment->starts_at->getTimestamp() - $now->getTimestamp()),
            ])
            ->first();

        if ($appointment === null) {
            return null;
        }

        $appointment->forceFill(['status' => AppointmentStatus::CheckedIn, 'order_id' => $order->id])->save();
        $this->auditTrail->record('appointment.checked_in', $appointment, $actor, 'Booked car checked in at the counter', [
            'order_id' => $order->id,
            'matched' => true,
        ]);

        return $appointment;
    }

    private function isFor(Appointment $appointment, Order $order): bool
    {
        if ($appointment->vehicle_id !== null || filled($appointment->plate_number)) {
            return ($order->vehicle_id !== null && $appointment->vehicle_id === $order->vehicle_id)
                || (filled($order->plate_number) && $appointment->plate_number === $order->plate_number);
        }

        return ($order->customer_id !== null && $appointment->customer_id === $order->customer_id)
            || (filled($order->customer?->phone) && $appointment->customer_phone === $order->customer->phone);
    }
}
