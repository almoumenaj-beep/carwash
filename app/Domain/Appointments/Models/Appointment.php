<?php

namespace App\Domain\Appointments\Models;

use App\Domain\Appointments\Enums\AppointmentStatus;
use App\Domain\Appointments\Policies\AppointmentPolicy;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A car booked to come in at a branch. Written by BookAppointment and CheckInAppointment.
 */
#[UsePolicy(AppointmentPolicy::class)]
class Appointment extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created booking is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'status' => 'booked',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'items' => 'array',
            'estimated_total' => 'integer',
            'starts_at' => 'immutable_datetime',
            'ends_at' => 'immutable_datetime',
            'status' => AppointmentStatus::class,
        ];
    }

    public function isBooked(): bool
    {
        return $this->status === AppointmentStatus::Booked;
    }

    /**
     * @return BelongsTo<Branch, $this>
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<Vehicle, $this>
     */
    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    /**
     * @return BelongsTo<VehicleSize, $this>
     */
    public function vehicleSize(): BelongsTo
    {
        return $this->belongsTo(VehicleSize::class);
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
