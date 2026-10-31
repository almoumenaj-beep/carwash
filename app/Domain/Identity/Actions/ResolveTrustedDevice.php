<?php

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Device;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Domain\Platform\Tenancy\TenantScope;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;

/**
 * Identifies a registered, non-revoked device by its identifier and secret, and makes its tenant current.
 */
class ResolveTrustedDevice
{
    public function __construct(private TenantContext $tenantContext) {}

    /**
     * @throws AuthenticationException
     * @throws AuthorizationException
     */
    public function handle(string $identifier, string $secret): Device
    {
        $device = Device::query()
            ->withoutGlobalScope(TenantScope::class)
            ->with('tenant')
            ->where('identifier', $identifier)
            ->whereNull('revoked_at')
            ->get()
            ->first(fn (Device $device) => $device->matchesSecret($secret));

        if ($device === null) {
            throw new AuthenticationException(__('This device is not registered or was revoked. Sign in with your password.'));
        }

        if (! $device->tenant->isActive()) {
            throw new AuthorizationException(__('This car wash account is suspended.'));
        }

        $this->tenantContext->set($device->tenant);

        return $device;
    }
}
