<?php

namespace App\Http\Requests;

use App\Domain\Catalog\Enums\PackageDiscountType;
use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creates (POST) or edits (PATCH) a service. Prices are integers in the currency's minor
 * unit (BHD: fils, so 2.500 BHD = 2500) and replace the whole price list when sent. A package
 * (is_package) lists the services it includes in package_service_ids, in display order, and is
 * priced from them less its discount: an amount in minor units, or a percentage in basis points.
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
            'is_package' => ['sometimes', 'boolean'],
            'package_discount_type' => ['sometimes', 'nullable', Rule::enum(PackageDiscountType::class)],
            'package_discount_value' => [
                'sometimes', 'integer', 'min:0',
                $this->input('package_discount_type') === PackageDiscountType::Percent->value ? 'max:10000' : 'max:100000000',
            ],
            'package_service_ids' => ['sometimes', 'array', 'max:20'],
            'package_service_ids.*' => ['uuid', 'distinct', Rule::exists('services', 'id')->where('tenant_id', $tenantId)],
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
