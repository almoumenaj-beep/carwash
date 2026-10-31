<?php

namespace App\Http\Resources;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServicePrice;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A service with its price list. Prices are integers in the currency's minor unit
 * (see `currency_decimals` in /settings) and include VAT when the car wash prices that way.
 *
 * @mixin Service
 */
class ServiceResource extends JsonResource
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
            'service_category_id' => $this->service_category_id,
            'name' => $this->name,
            'description' => $this->description,
            'duration_minutes' => $this->duration_minutes,
            'is_addon' => $this->is_addon,
            'sort_order' => $this->sort_order,
            'is_active' => $this->is_active,
            'prices' => $this->whenLoaded('prices', fn () => $this->prices->map(fn (ServicePrice $price) => [
                'vehicle_size_id' => $price->vehicle_size_id,
                'branch_id' => $price->branch_id,
                'price' => $price->price,
            ])->values()),
        ];
    }
}
