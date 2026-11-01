<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Opens the user's shift at a branch with the cash float in the drawer (minor units).
 */
class OpenCashShiftRequest extends FormRequest
{
    /**
     * Till staff of the branch; an unknown branch is reported by validation instead.
     */
    public function authorize(): bool
    {
        if (! $this->user()->can(Permission::PosCheckout->value)) {
            return false;
        }

        $branch = is_string($this->input('branch_id')) ? Branch::query()->find($this->input('branch_id')) : null;

        return $branch === null || $this->user()->canAccessBranch($branch);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'branch_id' => [
                'required', 'uuid',
                Rule::exists('branches', 'id')->where('tenant_id', $this->user()->tenant_id)->where('is_active', true)->whereNull('deleted_at'),
            ],
            'opening_float' => ['required', 'integer', 'between:0,100000000'],
        ];
    }
}
