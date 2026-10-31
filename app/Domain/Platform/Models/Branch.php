<?php

namespace App\Domain\Platform\Models;

use App\Domain\Platform\Policies\BranchPolicy;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\BranchFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A physical car wash location of a tenant.
 */
#[Fillable(['name', 'code', 'phone', 'address', 'opening_hours', 'is_active'])]
#[UseFactory(BranchFactory::class)]
#[UsePolicy(BranchPolicy::class)]
class Branch extends Model
{
    /** @use HasFactory<BranchFactory> */
    use BelongsToTenant, HasFactory, HasUuids, SoftDeletes;

    /**
     * Week days in display order for the Gulf (the week starts on Saturday).
     *
     * @var list<string>
     */
    public const WEEK_DAYS = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];

    /**
     * Hours a new branch starts with: open every day from 08:00 to 22:00.
     *
     * @return array<string, array{opens: string, closes: string}>
     */
    public static function defaultOpeningHours(): array
    {
        return array_fill_keys(self::WEEK_DAYS, ['opens' => '08:00', 'closes' => '22:00']);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'opening_hours' => 'array',
            'is_active' => 'boolean',
        ];
    }

    /**
     * Every week day, in display order; a missing or null day is closed.
     *
     * @return array<string, array{opens: string, closes: string}|null>
     */
    public function weeklyHours(): array
    {
        $hours = $this->opening_hours ?? [];

        return array_combine(self::WEEK_DAYS, array_map(fn (string $day) => $hours[$day] ?? null, self::WEEK_DAYS));
    }

    /**
     * @return HasMany<Bay, $this>
     */
    public function bays(): HasMany
    {
        return $this->hasMany(Bay::class);
    }
}
