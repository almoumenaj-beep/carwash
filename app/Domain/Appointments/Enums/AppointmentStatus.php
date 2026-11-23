<?php

namespace App\Domain\Appointments\Enums;

/**
 * Where a booking stands. A booking made on the customer page waits as pending until reception confirms
 * it (or the car simply shows up and is checked in); while open it holds a place in the schedule and can
 * still be changed, checked in, cancelled or marked as a no-show.
 */
enum AppointmentStatus: string
{
    case Pending = 'pending';
    case Booked = 'booked';
    case CheckedIn = 'checked_in';
    case Cancelled = 'cancelled';
    case NoShow = 'no_show';

    /**
     * The statuses of bookings still waiting for their car.
     *
     * @return list<self>
     */
    public static function open(): array
    {
        return [self::Pending, self::Booked];
    }
}
