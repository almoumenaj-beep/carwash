<?php

namespace App\Http\Resources;

use App\Domain\Crm\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Customer
 */
class CustomerResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'phone' => $this->phone,
            'name' => $this->name,
            'email' => $this->email,
            'marketing_consent' => $this->marketing_consent,
            'marketing_consent_at' => $this->marketing_consent_at?->toIso8601String(),
            'notes' => $this->notes,
            'last_visit_at' => $this->last_visit_at?->toIso8601String(),
            'points_balance' => $this->points_balance,
            'vehicles' => VehicleResource::collection($this->whenLoaded('vehicles')),
        ];
    }
}
