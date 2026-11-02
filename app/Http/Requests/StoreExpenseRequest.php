<?php

namespace App\Http\Requests;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Platform\Models\Branch;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Records an expense at a branch: paid now with a payment method, or owed when the method is left out
 * (owed to the supplier when one is given). Amounts in minor units.
 */
class StoreExpenseRequest extends FormRequest
{
    /**
     * Allowed to record expenses at this branch; an unknown branch is reported by validation instead.
     */
    public function authorize(): bool
    {
        $branch = is_string($this->input('branch_id')) ? Branch::query()->find($this->input('branch_id')) : null;

        return $branch === null || $this->user()->can('create', [Expense::class, $branch]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'branch_id' => ['required', 'uuid', Rule::exists('branches', 'id')->where('tenant_id', $tenantId)->whereNull('deleted_at')],
            'expense_category_id' => ['required', 'uuid', Rule::exists('expense_categories', 'id')->where('tenant_id', $tenantId)->where('is_active', true)],
            'supplier_id' => ['nullable', 'uuid', Rule::exists('suppliers', 'id')->where('tenant_id', $tenantId)],
            'amount' => ['required', 'integer', 'between:1,100000000'],
            'spent_on' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'description' => ['nullable', 'string', 'max:255'],
            'payment_method' => ['nullable', Rule::enum(ExpensePaymentMethod::class)],
        ];
    }
}
