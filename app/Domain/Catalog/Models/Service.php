<?php

namespace App\Domain\Catalog\Models;

use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\ServiceFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A sellable service, or an add-on (is_addon) sold together with one.
 */
#[Fillable(['service_category_id', 'name', 'description', 'duration_minutes', 'is_addon', 'sort_order', 'is_active'])]
#[UseFactory(ServiceFactory::class)]
class Service extends Model
{
    /** @use HasFactory<ServiceFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created service is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'duration_minutes' => 0,
        'is_addon' => false,
        'sort_order' => 0,
        'is_active' => true,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'duration_minutes' => 'integer',
            'is_addon' => 'boolean',
            'sort_order' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return BelongsTo<ServiceCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class, 'service_category_id');
    }

    /**
     * @return HasMany<ServicePrice, $this>
     */
    public function prices(): HasMany
    {
        return $this->hasMany(ServicePrice::class);
    }

    /**
     * The customer price in minor units for a vehicle size at a branch, or null when not priced.
     *
     * The most specific price wins: size at this branch, then the size anywhere,
     * then every size at this branch, then every size anywhere.
     */
    public function priceFor(?VehicleSize $size, ?Branch $branch = null): ?int
    {
        $candidates = [
            [$size?->id, $branch?->id],
            [$size?->id, null],
            [null, $branch?->id],
            [null, null],
        ];

        foreach ($candidates as [$sizeId, $branchId]) {
            $match = $this->prices->first(
                fn (ServicePrice $price) => $price->vehicle_size_id === $sizeId && $price->branch_id === $branchId,
            );

            if ($match !== null) {
                return $match->price;
            }
        }

        return null;
    }

    /**
     * Whether anything depends on the service, so it may only be deactivated, not deleted.
     * Work orders join this check when they arrive.
     */
    public function isInUse(): bool
    {
        return false;
    }
}
