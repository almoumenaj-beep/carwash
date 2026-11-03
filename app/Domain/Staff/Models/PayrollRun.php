<?php

namespace App\Domain\Staff\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A month's pay, drafted until paid. Written by the payroll actions.
 */
class PayrollRun extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created run is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'status' => 'draft',
        'total_net' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'month' => 'integer',
            'total_net' => 'integer',
            'paid_at' => 'datetime',
        ];
    }

    public function isPaid(): bool
    {
        return $this->status === 'paid';
    }

    /**
     * The first and last day of the month, in the car wash's time zone.
     *
     * @return array{CarbonImmutable, CarbonImmutable}
     */
    public function period(string $timezone): array
    {
        $start = CarbonImmutable::create($this->year, $this->month, 1, 0, 0, 0, $timezone);

        return [$start, $start->endOfMonth()];
    }

    /**
     * @return HasMany<PayrollLine, $this>
     */
    public function lines(): HasMany
    {
        return $this->hasMany(PayrollLine::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function payer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'paid_by');
    }
}
