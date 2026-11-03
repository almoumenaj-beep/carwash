<?php

namespace App\Domain\Appointments\Actions;

use App\Domain\Appointments\Enums\AppointmentStatus;
use App\Domain\Appointments\Models\Appointment;
use App\Domain\Orders\Actions\CheckInVehicle;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Checks in a booked car when it arrives: the order is opened as at the counter (the services may have
 * changed since the booking), and the booking is marked as checked in with its order.
 */
class CheckInAppointment
{
    public function __construct(private CheckInVehicle $checkInVehicle, private AuditTrail $auditTrail) {}

    /**
     * @param  array<string, mixed>  $orderData  As for CheckInVehicle.
     *
     * @throws ValidationException
     */
    public function handle(User $actor, Appointment $appointment, array $orderData): Order
    {
        return DB::transaction(function () use ($actor, $appointment, $orderData): Order {
            $appointment = Appointment::query()->lockForUpdate()->findOrFail($appointment->id);
            if (! $appointment->isBooked()) {
                throw ValidationException::withMessages(['appointment' => __('This booking is no longer waiting for the car.')]);
            }
            if ($orderData['branch_id'] !== $appointment->branch_id) {
                throw ValidationException::withMessages(['branch_id' => __('Check the car in at the branch it was booked at.')]);
            }

            $order = $this->checkInVehicle->handle($actor, $orderData);
            $appointment->forceFill(['status' => AppointmentStatus::CheckedIn, 'order_id' => $order->id])->save();

            $this->auditTrail->record('appointment.checked_in', $appointment, $actor, 'Booked car checked in', ['order_id' => $order->id]);

            return $order;
        });
    }
}
