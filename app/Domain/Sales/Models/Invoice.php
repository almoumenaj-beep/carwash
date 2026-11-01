<?php

namespace App\Domain\Sales\Models;

use App\Domain\Crm\Models\Customer;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A tax invoice for a paid order. Issued by CheckoutOrder and never changed afterwards, so
 * nothing is mass assignable.
 */
class Invoice extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created invoice is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'discount_total' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'number' => 'integer',
            'subtotal' => 'integer',
            'discount_total' => 'integer',
            'total' => 'integer',
            'vat_rate_bps' => 'integer',
            'prices_include_vat' => 'boolean',
            'vat_amount' => 'integer',
            'issued_at' => 'datetime',
        ];
    }

    /**
     * The number printed on the receipt, e.g. "MAIN-INV-17".
     */
    public function reference(): string
    {
        return "{$this->branch->code}-INV-{$this->number}";
    }

    /**
     * @return BelongsTo<Branch, $this>
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function issuer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'issued_by');
    }

    /**
     * @return HasMany<InvoiceLine, $this>
     */
    public function lines(): HasMany
    {
        return $this->hasMany(InvoiceLine::class);
    }

    /**
     * @return HasMany<Payment, $this>
     */
    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }
}
