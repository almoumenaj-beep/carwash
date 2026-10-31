<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;

class PinLoginRequest extends DeviceCredentialsRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            ...parent::rules(),
            'user_id' => ['required', 'uuid'],
            'pin' => ['required', 'digits_between:4,6'],
        ];
    }
}
