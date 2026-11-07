<?php

namespace App\Domain\Memberships\Models;

use App\Domain\Memberships\Enums\MembershipScope;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * A membership the owner offers. `washes` null means no limit. Plans are switched off, not deleted, to keep the
 * history of what was sold.
 */
#[Fillable(['name', 'price', 'washes', 'validity_days', 'scope', 'service_ids', 'is_active'])]
class MembershipPlan extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database default so a freshly created plan is complete before it is refreshed.
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
            'washes' => 'integer',
            'validity_days' => 'integer',
            'scope' => MembershipScope::class,
            'service_ids' => 'array',
            'is_active' => 'boolean',
        ];
    }
}
