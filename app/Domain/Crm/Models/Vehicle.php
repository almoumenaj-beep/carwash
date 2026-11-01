<?php

namespace App\Domain\Crm\Models;

use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\VehicleFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A customer's car. Its size picks the price of each service.
 */
#[Fillable(['customer_id', 'plate_number', 'vehicle_size_id', 'make', 'model', 'color', 'notes'])]
#[UseFactory(VehicleFactory::class)]
class Vehicle extends Model
{
    /** @use HasFactory<VehicleFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<VehicleSize, $this>
     */
    public function size(): BelongsTo
    {
        return $this->belongsTo(VehicleSize::class, 'vehicle_size_id');
    }

    /**
     * Whether anything depends on the vehicle (work orders), so it cannot be deleted.
     */
    public function isInUse(): bool
    {
        return false;
    }
}
