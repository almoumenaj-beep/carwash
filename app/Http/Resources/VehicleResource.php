<?php

namespace App\Http\Resources;

use App\Domain\Crm\Models\Vehicle;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Vehicle
 */
class VehicleResource extends JsonResource
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
            'customer_id' => $this->customer_id,
            'plate_number' => $this->plate_number,
            'vehicle_size_id' => $this->vehicle_size_id,
            'make' => $this->make,
            'model' => $this->model,
            'color' => $this->color,
            'notes' => $this->notes,
        ];
    }
}
