<?php

namespace App\Domain\Orders\Models;

use App\Domain\Catalog\Models\Service;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A service sold on a work order, with its name and price frozen at the time of sale. The services
 * of a package sold on the order are its unpriced children (parent_id).
 */
#[Fillable(['parent_id', 'service_id', 'name', 'is_addon', 'is_package', 'quantity', 'unit_price', 'line_total', 'duration_minutes'])]
class OrderItem extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_addon' => 'boolean',
            'is_package' => 'boolean',
            'quantity' => 'integer',
            'unit_price' => 'integer',
            'line_total' => 'integer',
            'duration_minutes' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<Service, $this>
     */
    public function service(): BelongsTo
    {
        return $this->belongsTo(Service::class);
    }
}
