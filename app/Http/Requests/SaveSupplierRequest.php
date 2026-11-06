<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creates (POST) or edits (PATCH) a supplier.
 */
class SaveSupplierRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can(Permission::ExpensesApprove->value)
            || ($this->isMethod('post') && $this->user()->can(Permission::InventoryPurchase->value));
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
                $this->isMethod('post') ? 'required' : 'sometimes', 'string', 'max:150',
                Rule::unique('suppliers')->where('tenant_id', $this->user()->tenant_id)->ignore($this->route('supplier')),
            ],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
