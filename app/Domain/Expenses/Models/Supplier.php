<?php

namespace App\Domain\Expenses\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\SupplierFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Someone the car wash pays: a supplier, the landlord, a maintenance company.
 */
#[Fillable(['name', 'phone', 'notes', 'is_active'])]
#[UseFactory(SupplierFactory::class)]
class Supplier extends Model
{
    /** @use HasFactory<SupplierFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created supplier is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
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
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return HasMany<Expense, $this>
     */
    public function expenses(): HasMany
    {
        return $this->hasMany(Expense::class);
    }
}
