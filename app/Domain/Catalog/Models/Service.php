<?php

namespace App\Domain\Catalog\Models;

use App\Domain\Catalog\Enums\PackageDiscountType;
use App\Domain\Orders\Models\OrderItem;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\ServiceFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\DB;

/**
 * A sellable service, an add-on (is_addon) sold together with one, or a package (is_package)
 * bundling several services at its own price.
 */
#[Fillable(['service_category_id', 'name', 'description', 'duration_minutes', 'is_addon', 'is_package', 'package_discount_type', 'package_discount_value', 'sort_order', 'is_active'])]
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
        'is_package' => false,
        'package_discount_value' => 0,
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
            'is_package' => 'boolean',
            'package_discount_type' => PackageDiscountType::class,
            'package_discount_value' => 'integer',
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
     * The services a package includes, in display order.
     *
     * @return BelongsToMany<Service, $this>
     */
    public function packageItems(): BelongsToMany
    {
        return $this->belongsToMany(Service::class, 'service_package_items', 'package_id', 'service_id')
            ->withPivot('sort_order')
            ->orderByPivot('sort_order');
    }

    /**
     * Whether a package includes this service, so it cannot be deleted.
     */
    public function isInAPackage(): bool
    {
        return DB::table('service_package_items')->where('service_id', $this->id)->exists();
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
     * then every size at this branch, then every size anywhere. A package costs its services'
     * prices less its discount, and has no price when one of them has none.
     */
    public function priceFor(?VehicleSize $size, ?Branch $branch = null): ?int
    {
        if ($this->is_package) {
            return $this->packagePriceFor($size, $branch);
        }

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
     * What the package's services cost separately for a vehicle size at a branch, or null when one
     * of them has no price.
     */
    public function separatePriceFor(?VehicleSize $size, ?Branch $branch = null): ?int
    {
        $total = 0;

        foreach ($this->packageItems as $service) {
            $price = $service->priceFor($size, $branch);

            if ($price === null) {
                return null;
            }

            $total += $price;
        }

        return $total;
    }

    private function packagePriceFor(?VehicleSize $size, ?Branch $branch): ?int
    {
        $full = $this->separatePriceFor($size, $branch);

        if ($full === null || $this->packageItems->isEmpty()) {
            return null;
        }

        return $full - ($this->package_discount_type?->discountOn($full, $this->package_discount_value) ?? 0);
    }

    /**
     * Whether the service has been sold, so it may only be deactivated, not deleted.
     */
    public function isInUse(): bool
    {
        return OrderItem::query()->where('service_id', $this->id)->exists();
    }
}
