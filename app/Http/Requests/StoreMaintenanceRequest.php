<?php

namespace App\Http\Requests;

use App\Domain\Equipment\Enums\MaintenanceKind;
use App\Domain\Equipment\Models\Equipment;
use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Records maintenance on equipment at a branch the user works in. A cost (minor units) needs the expense
 * category it is recorded under; it is owed to the supplier when no payment method is given.
 */
class StoreMaintenanceRequest extends FormRequest
{
    public function authorize(): bool
    {
        $equipment = $this->route('equipment');

        return $this->user()->can(Permission::EquipmentManage->value)
            && $equipment instanceof Equipment
            && $this->user()->canAccessBranch($equipment->branch);
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
            'kind' => ['required', Rule::enum(MaintenanceKind::class)],
            'performed_on' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'description' => ['nullable', 'string', 'max:255'],
            'cost' => ['nullable', 'integer', 'min:0', 'max:100000000'],
            'supplier_id' => ['nullable', 'uuid', Rule::exists('suppliers', 'id')->where('tenant_id', $tenantId)],
            'expense_category_id' => [
                Rule::requiredIf(fn () => (int) $this->input('cost') > 0), 'nullable', 'uuid',
                Rule::exists('expense_categories', 'id')->where('tenant_id', $tenantId)->where('is_active', true),
            ],
            'payment_method' => ['nullable', Rule::enum(ExpensePaymentMethod::class)],
        ];
    }
}
