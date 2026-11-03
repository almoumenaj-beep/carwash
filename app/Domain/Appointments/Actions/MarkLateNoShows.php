<?php

namespace App\Domain\Appointments\Actions;

use App\Domain\Appointments\Enums\AppointmentStatus;
use App\Domain\Appointments\Models\Appointment;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Carbon\CarbonImmutable;

/**
 * Marks as no-shows a tenant's bookings whose car has not come within the grace time the car wash set
 * (`appointment_grace_minutes`) after the booked time. Nothing is marked when no grace time is set.
 */
class MarkLateNoShows
{
    public function __construct(private TenantContext $tenantContext) {}

    /**
     * @return int How many bookings were marked.
     */
    public function handle(Tenant $tenant): int
    {
        if ($tenant->appointment_grace_minutes === null) {
            return 0;
        }

        return $this->tenantContext->run($tenant, fn (): int => Appointment::query()
            ->whereIn('status', AppointmentStatus::open())
            ->where('starts_at', '<=', CarbonImmutable::now()->subMinutes($tenant->appointment_grace_minutes)->utc())
            ->update(['status' => AppointmentStatus::NoShow, 'updated_at' => now()]));
    }
}
