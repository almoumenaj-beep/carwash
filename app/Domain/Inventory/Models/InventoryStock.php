<?php

namespace App\Domain\Inventory\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * A branch's stock of one material. Changed only through StockLedger, so nothing is mass assignable.
 */
#[Table('inventory_stock')]
class InventoryStock extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created row is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'quantity_milli' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'quantity_milli' => 'integer',
        ];
    }
}
