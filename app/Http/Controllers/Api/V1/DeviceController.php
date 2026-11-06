<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\RevokeDevice;
use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Audit\AuditTrail;
use App\Http\Controllers\Controller;
use App\Http\Resources\DeviceResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

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
     * Mark a device as shared, so staff switch users on it by PIN (optionally only staff of one branch), or
     * as personal.
     */
    public function update(Request $request, Device $device, AuditTrail $auditTrail): DeviceResource
    {
        Gate::authorize('update', $device);

        $validated = $request->validate([
            'is_shared' => ['required', 'boolean'],
            'shared_branch_id' => ['nullable', 'uuid', Rule::exists('branches', 'id')->where('tenant_id', $request->user()->tenant_id)->whereNull('deleted_at')],
        ]);
        $isShared = $request->boolean('is_shared');

        $device->forceFill([
            'is_shared' => $isShared,
            'shared_branch_id' => $isShared ? ($validated['shared_branch_id'] ?? null) : null,
        ])->save();

        $auditTrail->record('device.sharing_changed', $device, $request->user(), 'Device sharing changed', [
            'is_shared' => $device->is_shared,
            'shared_branch_id' => $device->shared_branch_id,
        ]);

        return DeviceResource::make($device);
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
