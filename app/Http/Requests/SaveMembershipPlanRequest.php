<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Memberships\Enums\MembershipScope;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Adds or changes a membership plan. An empty `washes` means no limit. Changing a plan leaves memberships already
 * sold as they were.
 */
class SaveMembershipPlanRequest extends FormRequest
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
        $required = $this->isMethod('post') ? 'required' : 'sometimes';

        return [
            'name' => [$required, 'string', 'max:255'],
            'price' => [$required, 'integer', 'between:1,100000000'],
            'washes' => ['nullable', 'integer', 'between:1,1000'],
            'validity_days' => [$required, 'integer', 'between:1,3650'],
            'scope' => [$required, Rule::enum(MembershipScope::class)],
            'service_ids' => [$required, 'array', 'min:1'],
            'service_ids.*' => [
                'uuid', 'distinct',
                Rule::exists('services', 'id')->where('tenant_id', $this->user()->tenant_id),
            ],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
