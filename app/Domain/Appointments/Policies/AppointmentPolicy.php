<?php

namespace App\Domain\Appointments\Policies;

use App\Domain\Identity\Enums\Permission;
use App\Models\User;

/**
 * Bookings are seen by staff who book cars (appointments.manage) and by those who check them in when they
 * arrive (orders.create).
 */
class AppointmentPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can(Permission::AppointmentsManage->value) || $user->can(Permission::OrdersCreate->value);
    }
}
