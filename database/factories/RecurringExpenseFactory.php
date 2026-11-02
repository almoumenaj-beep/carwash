<?php

namespace Database\Factories;

use App\Domain\Expenses\Enums\RecurrenceFrequency;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Expenses\Models\RecurringExpense;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<RecurringExpense>
 */
class RecurringExpenseFactory extends Factory
{
    /**
     * Define the model's default state: a monthly expense due today.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'branch_id' => Branch::factory(),
            'tenant_id' => fn (array $attributes) => Branch::query()->withoutGlobalScopes()->find($attributes['branch_id'])->tenant_id,
            'expense_category_id' => fn (array $attributes) => ExpenseCategory::factory()->state(['tenant_id' => $attributes['tenant_id']]),
            'supplier_id' => null,
            'amount' => fake()->numberBetween(1, 500) * 1000,
            'description' => null,
            'frequency' => RecurrenceFrequency::Monthly,
            'next_due_on' => now()->toDateString(),
            'is_active' => true,
            'created_by' => fn (array $attributes) => User::factory()->state(['tenant_id' => $attributes['tenant_id']]),
        ];
    }
}
