<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateSettingsRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user()->can(Permission::SettingsManage->value);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'locale' => ['sometimes', 'required', 'in:ar,en'],
            'timezone' => ['sometimes', 'required', 'timezone:all'],
            'vat_rate' => ['sometimes', 'required', 'numeric', 'between:0,100', 'decimal:0,2'],
            'prices_include_vat' => ['sometimes', 'required', 'boolean'],
            'vat_number' => ['sometimes', 'nullable', 'string', 'max:30'],
        ];
    }
}
