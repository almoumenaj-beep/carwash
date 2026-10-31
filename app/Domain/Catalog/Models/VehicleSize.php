<?php

namespace App\Domain\Catalog\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\VehicleSizeFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * A size class of vehicle that prices depend on (small, sedan, SUV, van/truck).
 */
#[Fillable(['name', 'sort_order', 'is_active'])]
#[UseFactory(VehicleSizeFactory::class)]
class VehicleSize extends Model
{
    /** @use HasFactory<VehicleSizeFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created size is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
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
            'sort_order' => 'integer',
            'is_active' => 'boolean',
        ];
    }
}
