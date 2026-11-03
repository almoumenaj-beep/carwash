<?php

namespace App\Domain\Appointments\Enums;

/**
 * Where a booking stands. A booked appointment is confirmed once the customer says they are coming; while
 * booked or confirmed it holds a place in the schedule and can still be changed, checked in, cancelled or
 * marked as a no-show.
 */
enum AppointmentStatus: string
{
    case Booked = 'booked';
    case Confirmed = 'confirmed';
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
        return [self::Booked, self::Confirmed];
    }
}
