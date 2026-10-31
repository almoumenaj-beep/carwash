<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\RevokeDevice;
use App\Domain\Identity\Models\Device;
use App\Http\Controllers\Controller;
use App\Http\Resources\DeviceResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

class DeviceController extends Controller
{
    /**
     * The car wash's registered devices, most recently used first.
     */
    public function index(): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Device::class);

        return DeviceResource::collection(
            Device::query()->latest('last_login_at')->orderBy('id')->get(),
        );
    }

    /**
     * Revoke a device: its session ends and it can no longer switch users by PIN.
     */
    public function destroy(Request $request, Device $device, RevokeDevice $revokeDevice): Response
    {
        Gate::authorize('delete', $device);

        $revokeDevice->handle($request->user(), $device);

        return response()->noContent();
    }
}
