<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creates (POST) or edits (PATCH) a service. Prices are integers in the currency's minor
 * unit (BHD: fils, so 2.500 BHD = 2500) and replace the whole price list when sent.
 */
class SaveServiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can(Permission::ServicesManage->value);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;
        $creating = $this->isMethod('post');

        return [
            'name' => [
                $creating ? 'required' : 'sometimes', 'string', 'max:150',
                Rule::unique('services')->where('tenant_id', $tenantId)->ignore($this->route('service')),
            ],
            'service_category_id' => ['sometimes', 'nullable', 'uuid', Rule::exists('service_categories', 'id')->where('tenant_id', $tenantId)],
            'description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'duration_minutes' => ['sometimes', 'integer', 'between:0,1440'],
            'is_addon' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'between:0,65535'],
            'is_active' => ['sometimes', 'boolean'],
            'prices' => ['sometimes', 'array', 'max:200'],
            'prices.*.vehicle_size_id' => ['nullable', 'uuid', Rule::exists('vehicle_sizes', 'id')->where('tenant_id', $tenantId)],
            'prices.*.branch_id' => [
                'nullable', 'uuid',
                Rule::exists('branches', 'id')->where('tenant_id', $tenantId)->whereNull('deleted_at'),
            ],
            'prices.*.price' => ['required', 'integer', 'between:0,100000000'],
        ];
    }
}
