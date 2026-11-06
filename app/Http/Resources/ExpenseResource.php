<?php

namespace App\Http\Resources;

use App\Domain\Expenses\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * An expense; `is_paid` false means it is still owed (to `supplier`, when set). Amounts in minor units.
 *
 * @mixin Expense
 */
class ExpenseResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'branch_id' => $this->branch_id,
            'category' => ['id' => $this->category->id, 'name' => $this->category->name],
            'supplier' => $this->supplier === null ? null : ['id' => $this->supplier->id, 'name' => $this->supplier->name],
            'amount' => $this->amount,
            'spent_on' => $this->spent_on->toDateString(),
            'description' => $this->description,
            'is_paid' => $this->isPaid(),
            'payment_method' => $this->payment_method,
            'paid_at' => $this->paid_at?->toIso8601String(),
            'is_recurring' => $this->recurring_expense_id !== null,
            'source' => $this->source(),
            'created_by' => ['id' => $this->creator->id, 'name' => $this->creator->name],
        ];
    }
}
