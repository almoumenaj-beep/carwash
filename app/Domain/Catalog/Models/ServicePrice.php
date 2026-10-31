<?php

namespace App\Domain\Catalog\Models;

use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\ServicePriceFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A price in minor units (BHD: fils), as charged to the customer. Null size = every size,
 * null branch = every branch.
 */
#[Fillable(['vehicle_size_id', 'branch_id', 'price'])]
#[UseFactory(ServicePriceFactory::class)]
class ServicePrice extends Model
{
    /** @use HasFactory<ServicePriceFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'price' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<Service, $this>
     */
    public function service(): BelongsTo
    {
        return $this->belongsTo(Service::class);
    }

    /**
     * @return BelongsTo<VehicleSize, $this>
     */
    public function vehicleSize(): BelongsTo
    {
        return $this->belongsTo(VehicleSize::class);
    }

    /**
     * @return BelongsTo<Branch, $this>
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }
}
