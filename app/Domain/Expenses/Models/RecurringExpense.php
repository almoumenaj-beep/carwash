<?php

namespace App\Domain\Expenses\Models;

use App\Domain\Expenses\Enums\RecurrenceFrequency;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Models\User;
use Database\Factories\RecurringExpenseFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * An expense that falls due on a schedule, such as the monthly rent.
 */
#[Fillable(['branch_id', 'expense_category_id', 'supplier_id', 'amount', 'description', 'frequency', 'next_due_on', 'is_active'])]
#[UseFactory(RecurringExpenseFactory::class)]
class RecurringExpense extends Model
{
    /** @use HasFactory<RecurringExpenseFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created schedule is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'is_active' => true,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'frequency' => RecurrenceFrequency::class,
            'next_due_on' => 'immutable_date',
            'is_active' => 'boolean',
        ];
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
     * @return BelongsTo<User, $this>
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
