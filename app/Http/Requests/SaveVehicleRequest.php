<?php

namespace App\Http\Requests;

use App\Domain\Crm\Support\PlateNumber;
use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Adds a car to a customer (POST) or edits one (PATCH); customer_id on PATCH transfers the car.
 */
class SaveVehicleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can(
            $this->isMethod('post') ? Permission::CustomersCreate->value : Permission::CustomersUpdate->value,
        );
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('plate_number'))) {
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
        $creating = $this->isMethod('post');

        return [
            'plate_number' => [
                $creating ? 'required' : 'sometimes', 'string', 'min:1', 'max:20',
                Rule::unique('vehicles', 'plate_number')->where('tenant_id', $tenantId)->ignore($this->route('vehicle')),
            ],
            'customer_id' => $creating
                ? ['prohibited']
                : ['sometimes', 'uuid', Rule::exists('customers', 'id')->where('tenant_id', $tenantId)],
            ...VehicleRules::for($tenantId),
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'plate_number.unique' => __('This plate is already registered to another customer.'),
        ];
    }
}
