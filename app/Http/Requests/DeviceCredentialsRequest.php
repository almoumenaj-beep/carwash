<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Requests made by a trusted device on behalf of nobody yet, e.g. before a PIN switch.
 */
class DeviceCredentialsRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'device_identifier' => ['required', 'string', 'max:100'],
            'device_secret' => ['required', 'string', 'max:255'],
        ];
    }
}
