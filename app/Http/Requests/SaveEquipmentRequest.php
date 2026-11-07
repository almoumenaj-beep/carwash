<?php

namespace App\Http\Requests;

use App\Domain\Equipment\Enums\EquipmentStatus;
use App\Domain\Equipment\Models\Equipment;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Adds (POST) or edits (PATCH) a piece of equipment at a branch the user works in. The purchase cost is in
 * minor units; `maintenance_interval_days` left empty means no periodic maintenance.
 */
class SaveEquipmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        if (! $this->user()->can(Permission::EquipmentManage->value)) {
            return false;
        }

        $equipment = $this->route('equipment');
        if ($equipment instanceof Equipment && ! $this->user()->canAccessBranch($equipment->branch)) {
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
        $required = $this->isMethod('post') ? 'required' : 'sometimes';

        return [
            'branch_id' => [$required, 'uuid', Rule::exists('branches', 'id')->where('tenant_id', $this->user()->tenant_id)->whereNull('deleted_at')],
            'name' => [$required, 'string', 'max:100'],
            'serial_number' => ['sometimes', 'nullable', 'string', 'max:100'],
            'purchased_on' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'purchase_cost' => ['sometimes', 'nullable', 'integer', 'min:0', 'max:100000000'],
            // Reporting a breakdown has its own route, which records the reason.
            'status' => ['sometimes', Rule::enum(EquipmentStatus::class)->except(EquipmentStatus::OutOfService)],
            'maintenance_interval_days' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:3650'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:255'],
        ];
    }
}
