<?php

namespace App\Domain\Equipment\Models;

use App\Domain\Equipment\Enums\EquipmentStatus;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Carbon\CarbonImmutable;
use Database\Factories\EquipmentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A machine or tool at a branch, e.g. "Pressure washer 2", with its periodic maintenance schedule.
 */
#[Fillable(['branch_id', 'name', 'serial_number', 'purchased_on', 'purchase_cost', 'status', 'maintenance_interval_days', 'notes'])]
#[Table('equipment')]
#[UseFactory(EquipmentFactory::class)]
class Equipment extends Model
{
    /** @use HasFactory<EquipmentFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created piece of equipment is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'status' => 'in_service',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => EquipmentStatus::class,
            'purchased_on' => 'immutable_date',
            'purchase_cost' => 'integer',
            'maintenance_interval_days' => 'integer',
            'last_maintained_on' => 'immutable_date',
            'next_maintenance_on' => 'immutable_date',
        ];
    }

    /**
     * Sets when periodic maintenance is next due: the interval after the last periodic maintenance, or after
     * purchase, or after it was added ([$today] while it is being added). Equipment without an interval is never due.
     */
    public function scheduleNextMaintenance(CarbonImmutable $today): void
    {
        $added = $this->created_at === null ? $today : CarbonImmutable::parse($this->created_at)->setTimezone($today->timezone)->startOfDay();
        $from = $this->last_maintained_on ?? $this->purchased_on ?? $added;

        $this->next_maintenance_on = $this->maintenance_interval_days === null
            ? null
            : $from->addDays($this->maintenance_interval_days);
    }

    /**
     * Days until periodic maintenance is due (negative once overdue), or null when none is scheduled.
     */
    public function daysUntilMaintenance(CarbonImmutable $today): ?int
    {
        if ($this->next_maintenance_on === null || $this->status === EquipmentStatus::Retired) {
            return null;
        }

        return (int) CarbonImmutable::parse($today->toDateString())->diffInDays($this->next_maintenance_on->toDateString(), false);
    }

    /**
     * @return BelongsTo<Branch, $this>
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * @return HasMany<EquipmentMaintenance, $this>
     */
    public function maintenances(): HasMany
    {
        return $this->hasMany(EquipmentMaintenance::class);
    }
}
