<?php

namespace App\Domain\Crm\Models;

use App\Domain\Crm\Support\PhoneNumber;
use App\Domain\Crm\Support\PlateNumber;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\CustomerFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Scope;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A customer of the car wash, identified by phone number and shared by all its branches.
 */
#[Fillable(['phone', 'name', 'email', 'notes'])]
#[UseFactory(CustomerFactory::class)]
class Customer extends Model
{
    /** @use HasFactory<CustomerFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created customer is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'marketing_consent' => false,
        'loyalty_stamps' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'marketing_consent' => 'boolean',
            'marketing_consent_at' => 'datetime',
            'last_visit_at' => 'datetime',
            'loyalty_stamps' => 'integer',
        ];
    }

    /**
     * @return HasMany<Vehicle, $this>
     */
    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }

    /**
     * Records the customer's choice about marketing messages, with when it was given.
     */
    public function setMarketingConsent(bool $consent): void
    {
        if ($consent !== $this->marketing_consent) {
            $this->forceFill(['marketing_consent' => $consent, 'marketing_consent_at' => $consent ? now() : null]);
        }
    }

    /**
     * @return HasMany<Order, $this>
     */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Whether the customer has history (work orders; later wallet and loyalty), so they cannot be deleted.
     */
    public function isInUse(): bool
    {
        return $this->orders()->exists();
    }

    /**
     * Customers whose name, phone or one of whose plates matches what the cashier typed.
     *
     * @param  Builder<self>  $query
     */
    #[Scope]
    protected function search(Builder $query, string $term): void
    {
        $term = trim($term);
        $digits = preg_replace('/\D/', '', PhoneNumber::westernDigits($term));
        $plate = PlateNumber::normalise($term);

        $query->where(function (Builder $query) use ($term, $digits, $plate): void {
            $query->where('name', 'like', '%'.addcslashes($term, '%_\\').'%')
                ->orWhereHas('vehicles', fn (Builder $vehicles) => $vehicles->where('plate_number', 'like', '%'.addcslashes($plate, '%_\\').'%'));

            if (strlen($digits) >= 3) {
                $query->orWhere('phone', 'like', '%'.ltrim($digits, '0').'%');
            }
        });
    }
}
