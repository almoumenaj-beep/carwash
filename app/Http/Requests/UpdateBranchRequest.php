<?php

namespace App\Http\Requests;

use App\Domain\Platform\Models\Branch;
use App\Rules\OpeningHoursDay;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class UpdateBranchRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('branch'));
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('code'))) {
            $this->merge(['code' => Str::upper(trim($this->input('code')))]);
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
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'code' => [
                'sometimes', 'required', 'string', 'regex:/^[A-Z0-9-]{1,20}$/',
                Rule::unique('branches')->where('tenant_id', $this->user()->tenant_id)->ignore($this->route('branch')),
            ],
            'phone' => ['sometimes', 'nullable', 'string', 'max:32'],
            'address' => ['sometimes', 'nullable', 'string', 'max:255'],
            'opening_hours' => ['sometimes', 'array:'.implode(',', Branch::WEEK_DAYS)],
            'opening_hours.*' => [new OpeningHoursDay],
            'is_active' => ['sometimes', 'required', 'boolean'],
        ];
    }
}
