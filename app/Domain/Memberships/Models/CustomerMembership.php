<?php

namespace App\Domain\Memberships\Models;

use App\Domain\Crm\Models\Vehicle;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Domain\Sales\Models\Invoice;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A membership a customer bought, with its own copy of the plan's terms. Written by the Membership actions, so
 * nothing is mass assignable.
 */
class CustomerMembership extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database default so a freshly sold membership is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'washes_used' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'washes' => 'integer',
            'washes_used' => 'integer',
            'service_ids' => 'array',
            'expires_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    /**
     * Washes left, or null when there is no limit.
     */
    public function washesLeft(): ?int
    {
        return $this->washes === null ? null : max(0, $this->washes - $this->washes_used);
    }

    /**
     * Whether a wash can still be taken from it.
     */
    public function isUsable(): bool
    {
        return $this->cancelled_at === null && $this->expires_at->isFuture() && $this->washesLeft() !== 0;
    }

    /**
     * The invoice it was sold on.
     *
     * @return BelongsTo<Invoice, $this>
     */
    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class);
    }

    /**
     * @return BelongsTo<Vehicle, $this>
     */
    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }
}
