<?php

namespace App\Domain\Sales\Models;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Domain\Sales\Enums\PaymentMethod;
use App\Models\User;
use Illuminate\Database\Eloquent\Attributes\Scope;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A cashier's shift at a branch's till. Opened and closed only through the Sales actions, so nothing
 * is mass assignable.
 */
class CashShift extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'opening_float' => 'integer',
            'opened_at' => 'datetime',
            'closed_at' => 'datetime',
            'expected_cash' => 'integer',
            'counted_cash' => 'integer',
            'variance' => 'integer',
        ];
    }

    /**
     * The shift $user has open at $branch, if any.
     */
    public static function openFor(User $user, Branch $branch): ?self
    {
        return static::query()->open()->where('opened_by', $user->id)->where('branch_id', $branch->id)->first();
    }

    public function isOpen(): bool
    {
        return $this->closed_at === null;
    }

    /**
     * Cash taken during the shift, after change was given.
     */
    public function cashTaken(): int
    {
        return (int) $this->payments()->where('method', PaymentMethod::Cash->value)->sum('amount');
    }

    /**
     * Cash taken out of the drawer during the shift to pay expenses.
     */
    public function cashPaidOut(): int
    {
        return (int) Expense::query()
            ->where('cash_shift_id', $this->id)
            ->where('payment_method', ExpensePaymentMethod::CashDrawer->value)
            ->sum('amount');
    }

    /**
     * What should be in the drawer now: the float plus the cash taken, less the expenses paid from it.
     */
    public function expectedCash(): int
    {
        return $this->opening_float + $this->cashTaken() - $this->cashPaidOut();
    }

    /**
     * @param  Builder<self>  $query
     */
    #[Scope]
    protected function open(Builder $query): void
    {
        $query->whereNull('closed_at');
    }

    /**
     * @return BelongsTo<Branch, $this>
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function opener(): BelongsTo
    {
        return $this->belongsTo(User::class, 'opened_by');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function closer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closed_by');
    }

    /**
     * @return HasMany<Payment, $this>
     */
    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }
}
