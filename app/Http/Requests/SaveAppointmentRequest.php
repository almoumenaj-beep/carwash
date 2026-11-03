<?php

namespace App\Http\Requests;

use App\Domain\Appointments\Models\Appointment;
use App\Domain\Crm\Support\PhoneNumber;
use App\Domain\Crm\Support\PlateNumber;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Books a car in (POST) or changes a booking (PATCH, the whole booking again): a registered vehicle_id,
 * or the customer's phone to reach them with the plate and size when known; the services as at check-in;
 * and `starts_at` as local time `YYYY-MM-DDTHH:MM` in the car wash's time zone.
 */
class SaveAppointmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        if (! $this->user()->can(Permission::AppointmentsManage->value)) {
            return false;
        }

        $appointment = $this->route('appointment');
        if ($appointment instanceof Appointment && ! $this->user()->canAccessBranch($appointment->branch)) {
            return false;
        }

        $branch = is_string($this->input('branch_id')) ? Branch::query()->find($this->input('branch_id')) : null;

        return $branch === null || $this->user()->canAccessBranch($branch);
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('plate_number')) && trim($this->input('plate_number')) !== '') {
            $this->merge(['plate_number' => PlateNumber::normalise($this->input('plate_number'))]);
        }

        if (is_string($this->input('customer_phone')) && trim($this->input('customer_phone')) !== '') {
            $this->merge(['customer_phone' => PhoneNumber::normalise($this->input('customer_phone'))]);
        }
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'branch_id' => ['required', 'uuid', Rule::exists('branches', 'id')->where('tenant_id', $tenantId)->where('is_active', true)->whereNull('deleted_at')],
            'starts_at' => ['required', 'date_format:Y-m-d\TH:i'],
            'vehicle_id' => ['nullable', 'uuid', Rule::exists('vehicles', 'id')->where('tenant_id', $tenantId)],
            'plate_number' => ['nullable', 'string', 'max:20'],
            'vehicle_size_id' => ['nullable', 'uuid', Rule::exists('vehicle_sizes', 'id')->where('tenant_id', $tenantId)],
            'customer_phone' => ['required_without:vehicle_id', 'nullable', 'string', 'regex:/^\+\d{8,15}$/'],
            'customer_name' => ['nullable', 'string', 'max:255'],
            'items' => ['required', 'array', 'min:1', 'max:30'],
            'items.*.service_id' => ['required', 'uuid', 'distinct', Rule::exists('services', 'id')->where('tenant_id', $tenantId)],
            'items.*.quantity' => ['sometimes', 'integer', 'between:1,20'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'customer_phone.regex' => __('Enter a valid phone number.'),
            'customer_phone.required_without' => __('Enter the customer\'s phone so the car wash can reach them.'),
        ];
    }
}
