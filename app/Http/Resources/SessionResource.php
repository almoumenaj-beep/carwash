<?php

namespace App\Http\Resources;

use App\Domain\Identity\Support\IssuedSession;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A new sign-in. The device secret appears only after a password login and must be stored by the app.
 *
 * @property IssuedSession $resource
 */
class SessionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'token' => $this->resource->plainTextToken,
            'token_type' => 'Bearer',
            'device' => [
                'id' => $this->resource->device->id,
                'name' => $this->resource->device->name,
                'secret' => $this->when($this->resource->deviceSecret !== null, $this->resource->deviceSecret),
            ],
            'user' => MeResource::make($this->resource->user->load('tenant', 'roles')),
        ];
    }
}
