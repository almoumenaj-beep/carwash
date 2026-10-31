<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateBayRequest extends FormRequest
{
    /**
     * Managing bays is managing the branch.
     */
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('bay')->branch);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $bay = $this->route('bay');

        return [
            'name' => [
                'sometimes', 'required', 'string', 'max:60',
                Rule::unique('bays')->where('branch_id', $bay->branch_id)->ignore($bay),
            ],
            'sort_order' => ['sometimes', 'integer', 'between:0,65535'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
