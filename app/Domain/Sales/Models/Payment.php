<?php

namespace App\Domain\Sales\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Domain\Sales\Enums\PaymentMethod;
use App\Models\User;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Money received for an invoice; `amount` is what stays in the till.
 */
#[Fillable(['branch_id', 'cash_shift_id', 'method', 'amount', 'tendered', 'change_given', 'received_by', 'received_at'])]
class Payment extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created payment is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'change_given' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'method' => PaymentMethod::class,
            'amount' => 'integer',
            'tendered' => 'integer',
            'change_given' => 'integer',
            'received_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function receiver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'received_by');
    }
}
