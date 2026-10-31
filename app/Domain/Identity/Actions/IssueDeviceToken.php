<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Starts the device's only session: ends whoever was signed in on it, then issues a token for the user.
 */
class IssueDeviceToken
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  'password'|'pin'  $method
     */
    public function handle(User $user, Device $device, string $method): string
    {
        return DB::transaction(function () use ($user, $device, $method): string {
            $device->tokens()->delete();

            $newToken = $user->createToken($device->name);
            $newToken->accessToken->forceFill(['device_id' => $device->id])->save();

            $device->forceFill(['last_login_at' => now()])->save();

            $this->auditTrail->record('auth.login', $user, $user, 'Signed in', [
                'method' => $method,
                'device_id' => $device->id,
            ]);

            return $newToken->plainTextToken;
        });
    }
}
