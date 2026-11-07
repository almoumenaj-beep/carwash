<?php

namespace App\Http\Requests;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Sales\Enums\PaymentMethod;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Sells a membership to a customer at the till.
 */
class SellMembershipRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can(Permission::PosCheckout->value);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'membership_plan_id' => ['required', 'uuid'],
            'branch_id' => ['required', 'uuid'],
            'method' => ['required', Rule::enum(PaymentMethod::class)],
            'vehicle_id' => ['nullable', 'uuid'],
        ];
    }
}
