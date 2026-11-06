<?php

namespace App\Domain\Staff\Models;

use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A staff member's time at a branch, from clocking in to clocking out. Written by the Staff actions.
 */
class AttendanceLog extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created record is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'auto_clocked_out' => false,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'clock_in_at' => 'datetime',
            'clock_out_at' => 'datetime',
            'auto_clocked_out' => 'boolean',
        ];
    }

    /**
     * The staff member's open record (clocked in, not out yet), if any.
     */
    public static function openFor(User $user): ?self
    {
        return static::query()->where('user_id', $user->id)->whereNull('clock_out_at')->latest('clock_in_at')->first();
    }

    /**
     * Minutes from clocking in to clocking out, or up to now while still at work.
     */
    public function minutesWorked(): int
    {
        return (int) $this->clock_in_at->diffInMinutes($this->clock_out_at ?? now());
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<Branch, $this>
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }
}
