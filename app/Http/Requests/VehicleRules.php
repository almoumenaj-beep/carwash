<?php

namespace App\Http\Requests;

use Illuminate\Validation\Rule;

/**
 * Validation rules for a car's descriptive fields, shared by customer registration and the vehicle endpoints.
 */
final class VehicleRules
{
    /**
     * @return array<string, list<mixed>>
     */
    public static function for(?string $tenantId, string $prefix = ''): array
    {
        return [
            "{$prefix}vehicle_size_id" => ['sometimes', 'nullable', 'uuid', Rule::exists('vehicle_sizes', 'id')->where('tenant_id', $tenantId)],
            "{$prefix}make" => ['sometimes', 'nullable', 'string', 'max:60'],
            "{$prefix}model" => ['sometimes', 'nullable', 'string', 'max:60'],
            "{$prefix}color" => ['sometimes', 'nullable', 'string', 'max:40'],
            "{$prefix}notes" => ['sometimes', 'nullable', 'string', 'max:2000'],
        ];
    }
}
