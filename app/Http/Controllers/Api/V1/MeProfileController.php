<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\UpdateStaffMember;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateOwnProfileRequest;
use App\Http\Resources\MeResource;

class MeProfileController extends Controller
{
    /**
     * Updates the signed-in staff member's own email or phone.
     */
    public function update(UpdateOwnProfileRequest $request, UpdateStaffMember $updateStaffMember): MeResource
    {
        $user = $updateStaffMember->handle($request->user(), $request->user(), $request->validated());

        return MeResource::make($user->load('tenant', 'roles'));
    }
}
