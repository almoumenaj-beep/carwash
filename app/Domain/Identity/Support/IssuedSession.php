<?php

namespace App\Domain\Identity\Support;

use App\Domain\Identity\Models\Device;
use App\Models\User;

/**
 * The outcome of a sign-in: the API token for the device and, after a password login,
 * the device's new secret that the app must store for PIN switching.
 */
final readonly class IssuedSession
{
    public function __construct(
        public User $user,
        public Device $device,
        public string $plainTextToken,
        public ?string $deviceSecret = null,
    ) {}
}
