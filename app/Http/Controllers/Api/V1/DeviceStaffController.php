<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\ResolveTrustedDevice;
use App\Http\Controllers\Controller;
use App\Http\Requests\DeviceCredentialsRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class DeviceStaffController extends Controller
{
    /**
     * Staff who can switch in on this trusted device with a PIN.
     *
     * @unauthenticated
     */
    public function __invoke(DeviceCredentialsRequest $request, ResolveTrustedDevice $resolveTrustedDevice): JsonResponse
    {
        $device = $resolveTrustedDevice->handle($request->validated('device_identifier'), $request->validated('device_secret'));

        $staff = User::query()
            ->where('tenant_id', $device->tenant_id)
            ->where('is_active', true)
            ->whereNotNull('pin_hash')
            ->orderBy('name')
            ->get(['id', 'name']);

        return response()->json(['data' => $staff->map(fn (User $user) => ['id' => $user->id, 'name' => $user->name])]);
    }
}
