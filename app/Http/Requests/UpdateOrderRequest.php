<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('order'));
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'items' => ['sometimes', 'array', 'min:1', 'max:30'],
            'items.*.service_id' => ['required', 'uuid', 'distinct', Rule::exists('services', 'id')->where('tenant_id', $this->user()->tenant_id)],
            'items.*.quantity' => ['sometimes', 'integer', 'between:1,20'],
            'bay_id' => ['sometimes', 'nullable', 'uuid'],
            'staff_ids' => ['sometimes', 'array', 'max:10'],
            'staff_ids.*' => ['uuid', 'distinct'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ];
    }
}
