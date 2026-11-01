<?php

namespace App\Http\Requests;

use App\Domain\Crm\Support\PhoneNumber;
use App\Domain\Crm\Support\PlateNumber;
use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Registers a customer, optionally with their cars. Phone and plates are normalised before
 * validation, so uniqueness is checked on the stored form.
 */
class StoreCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can(Permission::CustomersCreate->value);
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('phone')) && trim($this->input('phone')) !== '') {
            $this->merge(['phone' => PhoneNumber::normalise($this->input('phone'))]);
        }

        if (is_array($this->input('vehicles'))) {
            $this->merge(['vehicles' => array_map(
                fn ($vehicle) => is_array($vehicle) && is_string($vehicle['plate_number'] ?? null)
                    ? [...$vehicle, 'plate_number' => PlateNumber::normalise($vehicle['plate_number'])]
                    : $vehicle,
                $this->input('vehicles'),
            )]);
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
            'phone' => ['required', 'string', 'regex:/^\+\d{8,15}$/', Rule::unique('customers')->where('tenant_id', $tenantId)],
            'name' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'marketing_consent' => ['sometimes', 'boolean'],
            'vehicles' => ['sometimes', 'array', 'max:20'],
            ...VehicleRules::for($tenantId, 'vehicles.*.'),
            'vehicles.*.plate_number' => [
                'required', 'string', 'min:1', 'max:20', 'distinct',
                Rule::unique('vehicles', 'plate_number')->where('tenant_id', $tenantId),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'phone.unique' => __('A customer with this phone number already exists.'),
            'phone.regex' => __('Enter a valid phone number.'),
            'vehicles.*.plate_number.unique' => __('This plate is already registered to another customer.'),
        ];
    }
}
