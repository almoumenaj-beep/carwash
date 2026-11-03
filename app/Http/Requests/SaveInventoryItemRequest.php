<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creates (POST) or edits (PATCH) a material. `min_stock` is a decimal quantity of its unit.
 */
class SaveInventoryItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can(Permission::InventoryAdjust->value);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $required = $this->isMethod('post') ? 'required' : 'sometimes';

        return [
            'name' => [
                $required, 'string', 'max:100',
                Rule::unique('inventory_items')->where('tenant_id', $this->user()->tenant_id)->ignore($this->route('item')),
            ],
            'unit' => [$required, 'string', 'max:20'],
            'min_stock' => ['sometimes', 'numeric', 'min:0', 'max:1000000', 'decimal:0,3'],
            'unit_cost' => ['sometimes', 'integer', 'min:0', 'max:100000000'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
