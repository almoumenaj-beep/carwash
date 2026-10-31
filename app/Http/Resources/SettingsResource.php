<?php

namespace App\Http\Resources;

use App\Domain\Platform\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The car wash's settings. Money amounts elsewhere in the API are integers in the currency's
 * minor unit; `currency_decimals` says how to display them (BHD: 3, so 2500 → 2.500).
 *
 * @mixin Tenant
 */
class SettingsResource extends JsonResource
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
            'name' => $this->name,
            'currency' => $this->currency,
            'currency_decimals' => $this->currencyDecimals(),
            'locale' => $this->locale,
            'timezone' => $this->timezone,
            'vat_rate' => $this->vatRatePercent(),
            'prices_include_vat' => $this->prices_include_vat,
            'vat_number' => $this->vat_number,
        ];
    }
}
