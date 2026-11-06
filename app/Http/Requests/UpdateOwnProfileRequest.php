<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UpdateOwnProfileRequest extends FormRequest
{
    /**
     * Every signed-in staff member may edit their own name, email and phone.
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
        $user = $this->user();

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => ['sometimes', 'nullable', 'email', 'max:255', Rule::unique('users')->ignore($user)],
            'phone' => ['sometimes', 'nullable', 'string', 'max:32', Rule::unique('users')->ignore($user)],
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $email = $this->has('email') ? $this->input('email') : $this->user()->email;
            $phone = $this->has('phone') ? $this->input('phone') : $this->user()->phone;

            if (blank($email) && blank($phone)) {
                $validator->errors()->add('phone', __('Keep an email or a phone number to sign in with.'));
            }
        });
    }
}
