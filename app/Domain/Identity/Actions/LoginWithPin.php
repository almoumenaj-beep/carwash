<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Device;
use App\Domain\Identity\Support\IssuedSession;
use App\Domain\Identity\Support\SignInEligibility;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Switches the signed-in staff member on a shared device using their PIN. Too many wrong PINs lock it for a
 * while, recorded in the audit trail; the same answer is given for anyone who may not switch in here.
 */
class LoginWithPin
{
    private const MAX_ATTEMPTS = 5;

    private const LOCK_MINUTES = 15;

    public function __construct(
        private SignInEligibility $signInEligibility,
        private IssueDeviceToken $issueDeviceToken,
        private AuditTrail $auditTrail,
    ) {}

    /**
     * @throws ValidationException
     * @throws AuthorizationException
     */
    public function handle(Device $device, string $userId, string $pin): IssuedSession
    {
        if (! $device->is_shared) {
            throw new AuthorizationException(__('Switching users is not on for this device. Sign in with your password.'));
        }

        $user = User::query()->where('tenant_id', $device->tenant_id)->find($userId);

        if ($user === null || ! $device->allowsPinSignIn($user)) {
            throw ValidationException::withMessages(['pin' => __('The PIN is incorrect.')]);
        }

        if ($user->pin_locked_until?->isFuture()) {
            throw ValidationException::withMessages(['pin' => __('Too many wrong attempts. Try again in :minutes minutes.', [
                'minutes' => (int) ceil(now()->diffInSeconds($user->pin_locked_until) / 60),
            ])]);
        }

        if (! Hash::check($pin, $user->pin_hash)) {
            $this->recordWrongPin($user, $device);

            throw ValidationException::withMessages(['pin' => __('The PIN is incorrect.')]);
        }

        $this->signInEligibility->ensure($user);
        $user->forceFill(['pin_failed_attempts' => 0, 'pin_locked_until' => null])->save();

        return new IssuedSession($user, $device, $this->issueDeviceToken->handle($user, $device, 'pin'));
    }

    private function recordWrongPin(User $user, Device $device): void
    {
        $attempts = $user->pin_failed_attempts + 1;

        if ($attempts < self::MAX_ATTEMPTS) {
            $user->forceFill(['pin_failed_attempts' => $attempts])->save();

            return;
        }

        $user->forceFill(['pin_failed_attempts' => 0, 'pin_locked_until' => now()->addMinutes(self::LOCK_MINUTES)])->save();
        $this->auditTrail->record('user.pin_locked', $user, null, 'PIN locked after too many wrong attempts', [
            'device_id' => $device->id,
            'device_name' => $device->name,
        ]);
    }
}
