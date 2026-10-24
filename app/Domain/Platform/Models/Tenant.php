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

/**
 * A car wash business subscribed to the platform. Every operational record belongs to one tenant.
 */
#[Fillable(['name', 'slug', 'locale', 'currency', 'timezone'])]
#[UseFactory(TenantFactory::class)]
class Tenant extends Model
{
    /** @use HasFactory<TenantFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Mirrors the database defaults so a freshly created tenant is usable before it is refreshed.
     *
     * @var array<string, string>
     */
    protected $attributes = [
        'status' => 'active',
        'locale' => 'ar',
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
        ];
    }

    public function isActive(): bool
    {
        return $this->status === TenantStatus::Active;
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
