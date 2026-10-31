<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\LoginWithPassword;
use App\Domain\Identity\Actions\LoginWithPin;
use App\Domain\Identity\Actions\ResolveTrustedDevice;
use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\PinLoginRequest;
use App\Http\Resources\SessionResource;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class AuthController extends Controller
{
    /**
     * Sign in with email or phone and password. Registers the device and returns its secret.
     *
     * @unauthenticated
     */
    public function login(LoginRequest $request, LoginWithPassword $loginWithPassword): SessionResource
    {
        return SessionResource::make($loginWithPassword->handle(
            $request->validated('login'),
            $request->validated('password'),
            $request->validated('device_identifier'),
            $request->validated('device_name'),
            $request->validated('platform'),
        ));
    }

    /**
     * Switch the signed-in staff member on a trusted device with their PIN.
     *
     * @unauthenticated
     */
    public function pinLogin(PinLoginRequest $request, ResolveTrustedDevice $resolveTrustedDevice, LoginWithPin $loginWithPin): SessionResource
    {
        $device = $resolveTrustedDevice->handle($request->validated('device_identifier'), $request->validated('device_secret'));

        return SessionResource::make($loginWithPin->handle($device, $request->validated('user_id'), $request->validated('pin')));
    }

    /**
     * End the current session on this device.
     */
    public function logout(Request $request): Response
    {
        $request->user()->currentAccessToken()->delete();

        return response()->noContent();
    }
}
