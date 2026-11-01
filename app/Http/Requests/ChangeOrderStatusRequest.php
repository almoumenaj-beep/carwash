<?php

namespace App\Http\Requests;

use App\Domain\Orders\Enums\OrderStatus;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ChangeOrderStatusRequest extends FormRequest
{
    /**
     * Moving along the queue needs orders.update_status; cancelling needs orders.cancel.
     * An unknown status is reported by validation instead.
     */
    public function authorize(): bool
    {
        $next = OrderStatus::tryFrom((string) $this->input('status'));

        return $next === null || $this->user()->can('changeStatus', [$this->route('order'), $next]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'status' => ['required', Rule::enum(OrderStatus::class)],
            'reason' => ['required_if:status,'.OrderStatus::Cancelled->value, 'nullable', 'string', 'max:255'],
            'checklist' => ['sometimes', 'array'],
            'checklist.*.item_id' => ['required', 'uuid', 'distinct'],
            'checklist.*.passed' => ['required', 'boolean'],
        ];
    }
}
