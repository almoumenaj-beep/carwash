<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class SetUserPin
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function handle(User $user, string $pin): void
    {
        $user->forceFill(['pin_hash' => Hash::make($pin)])->save();

        $this->auditTrail->record('user.pin_changed', $user, $user, 'PIN changed');
    }
}
