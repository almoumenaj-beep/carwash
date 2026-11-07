<?php

namespace App\Domain\Orders\Models;

use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Policies\OrderPolicy;
use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Domain\Sales\Models\Invoice;
use App\Models\User;
use Database\Factories\OrderFactory;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * A work order: one car through the wash at a branch. Written only through the Orders actions,
 * so nothing is mass assignable.
 */
#[UseFactory(OrderFactory::class)]
#[UsePolicy(OrderPolicy::class)]
class Order extends Model
{
    /** @use HasFactory<OrderFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created order is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'status' => 'waiting',
        'subtotal' => 0,
        'estimated_minutes' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => OrderStatus::class,
            'number' => 'integer',
            'subtotal' => 'integer',
            'estimated_minutes' => 'integer',
            'started_at' => 'datetime',
            'qc_at' => 'datetime',
            'ready_at' => 'datetime',
            'delivered_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    /**
     * The number shown on screens and tickets, e.g. "MAIN-17".
     */
    public function reference(): string
    {
        return "{$this->branch->code}-{$this->number}";
    }

    /**
     * Writes priced lines (from OrderPricing) as the order's items; a package's services become its
     * unpriced child items.
     *
     * @param  list<array{service_id: string, name: string, is_addon: bool, is_package: bool, quantity: int, unit_price: int, line_total: int, duration_minutes: int, components: list<array{service_id: string, name: string}>}>  $lines
     */
    public function addItems(array $lines): void
    {
        foreach ($lines as $line) {
            $components = $line['components'];
            unset($line['components']);

            $item = $this->items()->create($line);

            foreach ($components as $component) {
                $this->items()->create([
                    ...$component,
                    'parent_id' => $item->id,
                    'is_addon' => false,
                    'is_package' => false,
                    'quantity' => 1,
                    'unit_price' => 0,
                    'line_total' => 0,
                    'duration_minutes' => 0,
                ]);
            }
        }
    }

    public function isPaid(): bool
    {
        return $this->invoice !== null;
    }

    /**
     * The statuses this order may move to now: the status machine, except that a car is only handed
     * over once paid, and a paid order is refunded rather than cancelled.
     *
     * @return list<OrderStatus>
     */
    public function allowedNext(): array
    {
        $paid = $this->isPaid();

        return array_values(array_filter(
            $this->status->allowedNext(),
            fn (OrderStatus $next) => match ($next) {
                OrderStatus::Delivered => $paid,
                OrderStatus::Cancelled => ! $paid,
                default => true,
            },
        ));
    }

    /**
     * @return BelongsTo<Branch, $this>
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<Vehicle, $this>
     */
    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    /**
     * @return BelongsTo<VehicleSize, $this>
     */
    public function vehicleSize(): BelongsTo
    {
        return $this->belongsTo(VehicleSize::class);
    }

    /**
     * @return BelongsTo<Bay, $this>
     */
    public function bay(): BelongsTo
    {
        return $this->belongsTo(Bay::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * @return HasMany<OrderItem, $this>
     */
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * @return BelongsToMany<User, $this>
     */
    public function staff(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'order_staff')->withTimestamps();
    }

    /**
     * @return HasMany<OrderStatusChange, $this>
     */
    public function statusHistory(): HasMany
    {
        return $this->hasMany(OrderStatusChange::class)->orderBy('created_at')->orderBy('id');
    }

    /**
     * @return HasMany<OrderQualityCheck, $this>
     */
    public function qualityChecks(): HasMany
    {
        return $this->hasMany(OrderQualityCheck::class)->orderBy('created_at')->orderBy('id');
    }

    /**
     * @return HasOne<Invoice, $this>
     */
    public function invoice(): HasOne
    {
        return $this->hasOne(Invoice::class)->whereNull('refunded_at');
    }

    /**
     * Invoices of this order that were given back, newest first.
     *
     * @return HasMany<Invoice, $this>
     */
    public function refundedInvoices(): HasMany
    {
        return $this->hasMany(Invoice::class)->whereNotNull('refunded_at')->latest('refunded_at');
    }
}
