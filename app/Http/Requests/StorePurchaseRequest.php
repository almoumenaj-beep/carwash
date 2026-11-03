<?php

namespace App\Http\Requests;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Records materials received at a branch: decimal quantities of each material's unit, costs per unit in
 * minor units, and how the purchase was paid (left out when it is owed to the supplier).
 */
class StorePurchaseRequest extends FormRequest
{
    public function authorize(): bool
    {
        if (! $this->user()->can(Permission::InventoryPurchase->value)) {
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

        return [
            'branch_id' => ['required', 'uuid', Rule::exists('branches', 'id')->where('tenant_id', $tenantId)->whereNull('deleted_at')],
            'supplier_id' => ['nullable', 'uuid', Rule::exists('suppliers', 'id')->where('tenant_id', $tenantId)],
            'expense_category_id' => ['required', 'uuid', Rule::exists('expense_categories', 'id')->where('tenant_id', $tenantId)->where('is_active', true)],
            'payment_method' => ['nullable', Rule::enum(ExpensePaymentMethod::class)],
            'purchased_on' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'note' => ['nullable', 'string', 'max:255'],
            'lines' => ['required', 'array', 'min:1', 'max:50'],
            'lines.*.inventory_item_id' => ['required', 'uuid', 'distinct', Rule::exists('inventory_items', 'id')->where('tenant_id', $tenantId)],
            'lines.*.quantity' => ['required', 'numeric', 'gt:0', 'max:1000000', 'decimal:0,3'],
            'lines.*.unit_cost' => ['required', 'integer', 'min:0', 'max:100000000'],
        ];
    }
}
