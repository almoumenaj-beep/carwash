<?php

namespace App\Http\Requests;

use App\Domain\Crm\Support\PlateNumber;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Branch;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Checks a car in: a registered vehicle_id, or a walk-in plate (with its size for pricing).
 */
class StoreOrderRequest extends FormRequest
{
    /**
     * Allowed to check cars in at this branch; an unknown branch is reported by validation instead.
     */
    public function authorize(): bool
    {
        $branch = is_string($this->input('branch_id')) ? Branch::query()->find($this->input('branch_id')) : null;

        return $branch === null || $this->user()->can('create', [Order::class, $branch]);
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('plate_number')) && trim($this->input('plate_number')) !== '') {
            $this->merge(['plate_number' => PlateNumber::normalise($this->input('plate_number'))]);
        }
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
            'branch_id' => ['required', 'uuid', Rule::exists('branches', 'id')->where('tenant_id', $tenantId)->where('is_active', true)->whereNull('deleted_at')],
            'vehicle_id' => ['nullable', 'uuid', Rule::exists('vehicles', 'id')->where('tenant_id', $tenantId)],
            'plate_number' => ['required_without:vehicle_id', 'nullable', 'string', 'max:20'],
            'vehicle_size_id' => ['nullable', 'uuid', Rule::exists('vehicle_sizes', 'id')->where('tenant_id', $tenantId)],
            'customer_id' => ['nullable', 'uuid', Rule::exists('customers', 'id')->where('tenant_id', $tenantId)],
            'items' => ['required', 'array', 'min:1', 'max:30'],
            'items.*.service_id' => ['required', 'uuid', 'distinct', Rule::exists('services', 'id')->where('tenant_id', $tenantId)],
            'items.*.quantity' => ['sometimes', 'integer', 'between:1,20'],
            'bay_id' => ['nullable', 'uuid'],
            'staff_ids' => ['sometimes', 'array', 'max:10'],
            'staff_ids.*' => ['uuid', 'distinct'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
