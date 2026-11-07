<?php

namespace App\Http\Requests;

use App\Domain\Equipment\Models\Equipment;
use App\Domain\Identity\Enums\Permission;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Reports equipment broken, with the reason.
 */
class StoreBreakdownRequest extends FormRequest
{
    public function authorize(): bool
    {
        $equipment = $this->route('equipment');

        return $this->user()->can(Permission::EquipmentManage->value)
            && $equipment instanceof Equipment
            && $this->user()->canAccessBranch($equipment->branch);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'max:255'],
        ];
    }
}
