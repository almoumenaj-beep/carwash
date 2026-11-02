<?php

namespace App\Http\Requests;

use App\Domain\Expenses\Enums\RecurrenceFrequency;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creates (POST) or edits (PATCH) a recurring expense at a branch the user works in.
 */
class SaveRecurringExpenseRequest extends FormRequest
{
    public function authorize(): bool
    {
        if (! $this->user()->can(Permission::ExpensesApprove->value)) {
            return false;
        }

        $current = $this->route('recurring_expense')?->branch;
        if ($current !== null && ! $this->user()->canAccessBranch($current)) {
            return false;
        }

        $branch = is_string($this->input('branch_id')) ? Branch::query()->find($this->input('branch_id')) : null;

        return $branch === null || $this->user()->canAccessBranch($branch);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;
        $required = $this->isMethod('post') ? 'required' : 'sometimes';

        return [
            'branch_id' => [$required, 'uuid', Rule::exists('branches', 'id')->where('tenant_id', $tenantId)->whereNull('deleted_at')],
            'expense_category_id' => [$required, 'uuid', Rule::exists('expense_categories', 'id')->where('tenant_id', $tenantId)],
            'supplier_id' => ['sometimes', 'nullable', 'uuid', Rule::exists('suppliers', 'id')->where('tenant_id', $tenantId)],
            'amount' => [$required, 'integer', 'between:1,100000000'],
            'description' => ['sometimes', 'nullable', 'string', 'max:255'],
            'frequency' => [$required, Rule::enum(RecurrenceFrequency::class)],
            'next_due_on' => [$required, 'date_format:Y-m-d'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
