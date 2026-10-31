<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Device;
use App\Domain\Identity\Support\IssuedSession;
use App\Domain\Identity\Support\SignInEligibility;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Switches the signed-in staff member on a trusted device using their PIN.
 */
class LoginWithPin
{
    public function __construct(private SignInEligibility $signInEligibility, private IssueDeviceToken $issueDeviceToken) {}

    /**
     * @throws ValidationException
     * @throws AuthorizationException
     */
    public function handle(Device $device, string $userId, string $pin): IssuedSession
    {
        $user = User::query()->where('tenant_id', $device->tenant_id)->find($userId);

        if ($user === null || $user->pin_hash === null || ! Hash::check($pin, $user->pin_hash)) {
            throw ValidationException::withMessages(['pin' => __('The PIN is incorrect.')]);
        }

        $this->signInEligibility->ensure($user);

        return new IssuedSession($user, $device, $this->issueDeviceToken->handle($user, $device, 'pin'));
    }
}
