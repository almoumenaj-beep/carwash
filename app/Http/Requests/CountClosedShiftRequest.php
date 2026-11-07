<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Sales\Models\CashShift;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Records the cash counted for a shift closed automatically: for staff who both close tills and see the
 * sales reports (the owner and branch managers by default), at a branch they work in.
 */
class CountClosedShiftRequest extends FormRequest
{
    public function authorize(): bool
    {
        /** @var CashShift $shift */
        $shift = $this->route('shift');

        return $this->user()->can(Permission::PosCloseShift->value)
            && $this->user()->can(Permission::ReportsSales->value)
            && $this->user()->canAccessBranch($shift->branch);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'counted_cash' => ['required', 'integer', 'between:0,100000000'],
            'note' => ['nullable', 'string', 'max:255'],
        ];
    }
}
