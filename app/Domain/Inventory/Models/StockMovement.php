<?php

namespace App\Domain\Inventory\Models;

use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Attributes\WithoutTimestamps;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * One change to a branch's stock, with the balance after it. Written only by StockLedger.
 */
#[WithoutTimestamps]
class StockMovement extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Keep microseconds, so movements written in the same second stay in order.
     */
    protected $dateFormat = 'Y-m-d H:i:s.u';

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'reason' => StockMovementReason::class,
            'change_milli' => 'integer',
            'balance_milli' => 'integer',
            'created_at' => 'datetime:Y-m-d H:i:s.u',
        ];
    }

    /**
     * @return BelongsTo<InventoryItem, $this>
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(InventoryItem::class, 'inventory_item_id');
    }

    /**
     * The staff member who received materials issued by hand.
     *
     * @return BelongsTo<User, $this>
     */
    public function receiver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'issued_to');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
