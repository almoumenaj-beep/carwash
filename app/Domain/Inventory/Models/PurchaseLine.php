<?php

namespace App\Domain\Inventory\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A material on a purchase: quantity in thousandths of its unit, cost per unit in minor units.
 */
#[Fillable(['inventory_item_id', 'quantity_milli', 'unit_cost', 'line_total'])]
class PurchaseLine extends Model
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
            'quantity_milli' => 'integer',
            'unit_cost' => 'integer',
            'line_total' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<InventoryItem, $this>
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(InventoryItem::class, 'inventory_item_id');
    }
}
