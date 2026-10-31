<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\SyncUserRoles;
use App\Http\Controllers\Controller;
use App\Http\Requests\SyncUserRolesRequest;
use App\Http\Resources\RoleResource;
use App\Models\User;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class UserRoleController extends Controller
{
    /**
     * Replace the staff member's roles with the given set and return their roles.
     */
    public function update(SyncUserRolesRequest $request, User $user, SyncUserRoles $syncUserRoles): AnonymousResourceCollection
    {
        $syncUserRoles->handle($request->user(), $user, $request->validated('roles'));

        return RoleResource::collection($user->roles()->orderBy('id')->get());
    }
}
