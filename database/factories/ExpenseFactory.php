<?php

namespace Database\Factories;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Expense>
 */
class ExpenseFactory extends Factory
{
    /**
     * Define the model's default state: an expense paid by bank transfer today.
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
            'amount' => fake()->numberBetween(1, 200) * 500,
            'spent_on' => now()->toDateString(),
            'description' => null,
            'payment_method' => ExpensePaymentMethod::BankTransfer,
            'paid_at' => now(),
            'created_by' => fn (array $attributes) => User::factory()->state(['tenant_id' => $attributes['tenant_id']]),
        ];
    }

    /**
     * Still owed, not paid yet.
     */
    public function unpaid(): static
    {
        return $this->state(['payment_method' => null, 'paid_at' => null]);
    }
}
