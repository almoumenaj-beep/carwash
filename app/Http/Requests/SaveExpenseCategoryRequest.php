<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creates (POST) or edits (PATCH) an expense category.
 */
class SaveExpenseCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can(Permission::ExpensesApprove->value);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => [
                $this->isMethod('post') ? 'required' : 'sometimes', 'string', 'max:100',
                Rule::unique('expense_categories')->where('tenant_id', $this->user()->tenant_id)->ignore($this->route('expense_category')),
            ],
            'sort_order' => ['sometimes', 'integer', 'between:0,65535'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
