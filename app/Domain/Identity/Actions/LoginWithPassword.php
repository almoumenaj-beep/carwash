<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Device;
use App\Domain\Identity\Support\IssuedSession;
use App\Domain\Identity\Support\SignInEligibility;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * Signs a staff member in with email or phone and password, registering the device they use
 * (or re-trusting it after a revocation) with a freshly rotated secret.
 */
class LoginWithPassword
{
    public function __construct(
        private SignInEligibility $signInEligibility,
        private TenantContext $tenantContext,
        private IssueDeviceToken $issueDeviceToken,
    ) {}

    /**
     * @throws ValidationException
     * @throws AuthorizationException
     */
    public function handle(string $login, string $password, string $deviceIdentifier, string $deviceName, ?string $platform): IssuedSession
    {
        $user = User::query()->where('email', $login)->orWhere('phone', $login)->first();

        if ($user === null || ! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages(['login' => __('auth.failed')]);
        }

        $this->signInEligibility->ensure($user);
        $this->tenantContext->set($user->tenant);

        $deviceSecret = Str::random(48);

        return DB::transaction(function () use ($user, $deviceIdentifier, $deviceName, $platform, $deviceSecret): IssuedSession {
            $device = Device::query()->firstOrNew(['identifier' => $deviceIdentifier]);
            $device->fill(['name' => $deviceName, 'platform' => $platform]);
            $device->forceFill(['secret_hash' => Device::hashSecret($deviceSecret), 'revoked_at' => null])->save();

            $token = $this->issueDeviceToken->handle($user, $device, 'password');

            return new IssuedSession($user, $device, $token, $deviceSecret);
        });
    }
}
