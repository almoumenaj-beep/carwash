<?php

namespace App\Domain\Expenses\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\ExpenseCategoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * What money is spent on, e.g. rent or cleaning supplies.
 */
#[Fillable(['name', 'sort_order', 'is_active'])]
#[UseFactory(ExpenseCategoryFactory::class)]
class ExpenseCategory extends Model
{
    /** @use HasFactory<ExpenseCategoryFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created category is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'sort_order' => 0,
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
            'sort_order' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return HasMany<Expense, $this>
     */
    public function expenses(): HasMany
    {
        return $this->hasMany(Expense::class);
    }

    /**
     * Whether expenses or recurring expenses use the category, so it may only be deactivated.
     */
    public function isInUse(): bool
    {
        return $this->expenses()->exists() || RecurringExpense::query()->where('expense_category_id', $this->id)->exists();
    }
}
