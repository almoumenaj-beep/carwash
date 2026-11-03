<?php

namespace App\Domain\Inventory\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\InventoryItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A material kept in stock, e.g. "Car shampoo" counted in litres.
 */
#[Fillable(['name', 'unit', 'unit_cost', 'min_stock_milli', 'is_active'])]
#[UseFactory(InventoryItemFactory::class)]
class InventoryItem extends Model
{
    /** @use HasFactory<InventoryItemFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created item is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'unit_cost' => 0,
        'min_stock_milli' => 0,
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
            'unit_cost' => 'integer',
            'min_stock_milli' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return HasMany<InventoryStock, $this>
     */
    public function stock(): HasMany
    {
        return $this->hasMany(InventoryStock::class);
    }
}
