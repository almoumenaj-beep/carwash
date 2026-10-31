<?php

namespace App\Http\Resources;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The signed-in staff member with everything the app needs to adapt its menus:
 * tenant, roles, effective permissions and the branches they may work in.
 *
 * @mixin User
 */
class MeResource extends JsonResource
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
            'email' => $this->email,
            'tenant' => [
                'id' => $this->tenant->id,
                'name' => $this->tenant->name,
                'locale' => $this->tenant->locale,
                'currency' => $this->tenant->currency,
                'timezone' => $this->tenant->timezone,
            ],
            'is_owner' => $this->isOwner(),
            'all_branches' => $this->hasAllBranchAccess(),
            'roles' => RoleResource::collection($this->roles),
            'permissions' => $this->permissionNames(),
            'branches' => BranchResource::collection($this->accessibleBranches()),
        ];
    }
}
