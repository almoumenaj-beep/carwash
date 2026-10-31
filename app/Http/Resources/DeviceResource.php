<?php

namespace App\Http\Resources;

use App\Domain\Identity\Models\Device;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Device
 */
class DeviceResource extends JsonResource
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
            'platform' => $this->platform,
            'last_login_at' => $this->last_login_at?->toIso8601String(),
            'revoked_at' => $this->revoked_at?->toIso8601String(),
            'is_revoked' => $this->isRevoked(),
        ];
    }
}
