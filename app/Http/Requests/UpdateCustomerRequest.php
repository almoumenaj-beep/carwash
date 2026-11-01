<?php

namespace App\Http\Requests;

use App\Domain\Crm\Support\PhoneNumber;
use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can(Permission::CustomersUpdate->value);
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('phone')) && trim($this->input('phone')) !== '') {
            $this->merge(['phone' => PhoneNumber::normalise($this->input('phone'))]);
        }
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'phone' => [
                'sometimes', 'required', 'string', 'regex:/^\+\d{8,15}$/',
                Rule::unique('customers')->where('tenant_id', $this->user()->tenant_id)->ignore($this->route('customer')),
            ],
            'name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'email' => ['sometimes', 'nullable', 'email', 'max:255'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'marketing_consent' => ['sometimes', 'boolean'],
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
        ];
    }
}
