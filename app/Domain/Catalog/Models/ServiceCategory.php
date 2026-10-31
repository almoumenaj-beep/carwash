<?php

namespace App\Domain\Catalog\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\ServiceCategoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'sort_order', 'is_active'])]
#[UseFactory(ServiceCategoryFactory::class)]
class ServiceCategory extends Model
{
    /** @use HasFactory<ServiceCategoryFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created category is complete before it is refreshed.
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

    /**
     * @return HasMany<Service, $this>
     */
    public function services(): HasMany
    {
        return $this->hasMany(Service::class);
    }
}
