<?php

namespace App\Domain\Expenses\Models;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Policies\ExpensePolicy;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Domain\Sales\Models\CashShift;
use App\Models\User;
use Database\Factories\ExpenseFactory;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Money spent by a branch, paid or still owed. Written only through the Expenses actions, so nothing
 * is mass assignable.
 */
#[UseFactory(ExpenseFactory::class)]
#[UsePolicy(ExpensePolicy::class)]
class Expense extends Model
{
    /** @use HasFactory<ExpenseFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'spent_on' => 'immutable_date',
            'payment_method' => ExpensePaymentMethod::class,
            'paid_at' => 'datetime',
        ];
    }

    public function isPaid(): bool
    {
        return $this->paid_at !== null;
    }

    /**
     * @return BelongsTo<Branch, $this>
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * @return BelongsTo<ExpenseCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ExpenseCategory::class, 'expense_category_id');
    }

    /**
     * @return BelongsTo<Supplier, $this>
     */
    public function supplier(): BelongsTo
    {
        return $this->belongsTo(Supplier::class);
    }

    /**
     * @return BelongsTo<CashShift, $this>
     */
    public function cashShift(): BelongsTo
    {
        return $this->belongsTo(CashShift::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
