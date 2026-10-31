<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creates (POST) or edits (PATCH) a service category.
 */
class SaveServiceCategoryRequest extends FormRequest
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
        $creating = $this->isMethod('post');

        return [
            'name' => [
                $creating ? 'required' : 'sometimes', 'string', 'max:100',
                Rule::unique('service_categories')->where('tenant_id', $this->user()->tenant_id)->ignore($this->route('service_category')),
            ],
            'sort_order' => ['sometimes', 'integer', 'between:0,65535'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
