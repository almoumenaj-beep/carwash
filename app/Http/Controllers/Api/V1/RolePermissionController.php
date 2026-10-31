<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\SyncRolePermissions;
use App\Domain\Identity\Models\Role;
use App\Http\Controllers\Controller;
use App\Http\Requests\SyncRolePermissionsRequest;
use App\Http\Resources\RoleResource;

class RolePermissionController extends Controller
{
    /**
     * Replace the role's permissions with the given set.
     */
    public function update(SyncRolePermissionsRequest $request, Role $role, SyncRolePermissions $syncRolePermissions): RoleResource
    {
        $syncRolePermissions->handle($request->user(), $role, $request->validated('permissions'));

        return RoleResource::make($role->load('permissions')->loadCount('users'));
    }
}
