<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Sales\Models\CashShift;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Closes the user's own shift with the cash counted in the drawer (minor units).
 */
class CloseCashShiftRequest extends FormRequest
{
    public function authorize(): bool
    {
        /** @var CashShift $shift */
        $shift = $this->route('shift');

        return $this->user()->can(Permission::PosCloseShift->value) && $shift->opened_by === $this->user()->id;
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
