<?php

namespace App\Domain\Expenses\Models;

use App\Domain\Equipment\Models\EquipmentMaintenance;
use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Policies\ExpensePolicy;
use App\Domain\Inventory\Models\Purchase;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Domain\Sales\Models\CashShift;
use App\Domain\Staff\Models\PayrollRun;
use App\Models\User;
use Database\Factories\ExpenseFactory;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

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

    /**
     * Where the expense was recorded from, when it is the money side of something else: it is then managed
     * there, not from the expenses. Null for an expense recorded by itself.
     */
    public function source(): ?string
    {
        return match (true) {
            $this->purchase !== null => 'purchase',
            $this->payrollRun !== null => 'payroll',
            $this->maintenance !== null => 'maintenance',
            default => null,
        };
    }

    /**
     * @return HasOne<Purchase, $this>
     */
    public function purchase(): HasOne
    {
        return $this->hasOne(Purchase::class);
    }

    /**
     * @return HasOne<PayrollRun, $this>
     */
    public function payrollRun(): HasOne
    {
        return $this->hasOne(PayrollRun::class);
    }

    /**
     * @return HasOne<EquipmentMaintenance, $this>
     */
    public function maintenance(): HasOne
    {
        return $this->hasOne(EquipmentMaintenance::class);
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
