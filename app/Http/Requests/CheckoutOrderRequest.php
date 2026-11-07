<?php

namespace App\Http\Requests;

use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Sales\Enums\PaymentMethod;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Pays for an order: an optional discount (an amount, or a percentage in basis points) with its
 * reason, the cash handed over, and whether to hand a ready car over at the same time.
 */
class CheckoutOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        $order = $this->route('order');

        if (! $this->user()->can('checkout', $order)) {
            return false;
        }

        return ! $this->boolean('deliver') || $this->user()->can('changeStatus', [$order, OrderStatus::Delivered]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'discount_amount' => ['nullable', 'integer', 'min:0', 'prohibits:discount_percent_bps'],
            'discount_percent_bps' => ['nullable', 'integer', 'between:0,10000'],
            'discount_reason' => ['nullable', 'string', 'max:255'],
            'method' => ['sometimes', Rule::enum(PaymentMethod::class)],
            'tendered' => ['nullable', 'integer', 'min:0'],
            'deliver' => ['sometimes', 'boolean'],
            'redeem_points' => ['nullable', 'integer', 'min:1'],
            'membership_id' => ['nullable', 'uuid'],
        ];
    }
}
