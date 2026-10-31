<?php

namespace App\Domain\Platform\Models;

use App\Domain\Platform\Enums\TenantStatus;
use App\Models\User;
use Database\Factories\TenantFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use NumberFormatter;

/**
 * A car wash business subscribed to the platform. Every operational record belongs to one tenant.
 */
#[Fillable(['name', 'slug', 'locale', 'currency', 'timezone', 'vat_rate_bps', 'prices_include_vat', 'vat_number'])]
#[UseFactory(TenantFactory::class)]
class Tenant extends Model
{
    /** @use HasFactory<TenantFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Mirrors the database defaults so a freshly created tenant is usable before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'status' => 'active',
        'locale' => 'ar',
        'vat_rate_bps' => 1000,
        'prices_include_vat' => true,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => TenantStatus::class,
            'vat_rate_bps' => 'integer',
            'prices_include_vat' => 'boolean',
        ];
    }

    public function isActive(): bool
    {
        return $this->status === TenantStatus::Active;
    }

    /**
     * The VAT rate as a percentage, e.g. 10.0.
     */
    public function vatRatePercent(): float
    {
        return $this->vat_rate_bps / 100;
    }

    /**
     * Decimal places of the tenant's currency (3 for BHD: 1 dinar = 1000 fils), per ISO 4217.
     */
    public function currencyDecimals(): int
    {
        return (new NumberFormatter("en@currency={$this->currency}", NumberFormatter::CURRENCY))
            ->getAttribute(NumberFormatter::FRACTION_DIGITS);
    }

    /**
     * Branches are tenant-scoped, so this relation is only usable while this tenant is the current tenant.
     *
     * @return HasMany<Branch, $this>
     */
    public function branches(): HasMany
    {
        return $this->hasMany(Branch::class);
    }

    /**
     * @return HasMany<User, $this>
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }
}
