<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Cuts off a lost or retired device: its session ends now and it can no longer switch users by PIN.
 */
class RevokeDevice
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function handle(User $actor, Device $device): void
    {
        DB::transaction(function () use ($actor, $device): void {
            $device->tokens()->delete();
            $device->forceFill(['revoked_at' => now()])->save();

            $this->auditTrail->record('device.revoked', $device, $actor, 'Device revoked', [
                'name' => $device->name,
            ]);
        });
    }
}
