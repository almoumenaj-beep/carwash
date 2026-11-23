<?php

namespace App\Domain\Offers\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Scope;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * An offer shown on the car wash's public customer page. Active until switched off or until its expiry
 * day passes. Amounts in minor units.
 */
#[Fillable(['title', 'description', 'price', 'expires_on', 'is_active'])]
class Offer extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created offer is complete before it is refreshed.
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
            'price' => 'integer',
            'expires_on' => 'immutable_date',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @param  Builder<self>  $query
     */
    #[Scope]
    protected function visible(Builder $query, CarbonImmutable $day): void
    {
        $query->where('is_active', true)
            ->where(fn (Builder $query) => $query->whereNull('expires_on')->orWhere('expires_on', '>=', $day->toDateString()));
    }
}
