<?php

namespace App\Domain\Platform\Tenancy;

use App\Domain\Platform\Models\Tenant;

/**
 * Holds the tenant of the current request or job. Registered as a scoped singleton,
 * so it is reset between requests and queued jobs.
 */
class TenantContext
{
    private ?Tenant $tenant = null;

    /**
     * Make the given tenant current, including for spatie/permission team lookups.
     */
    public function set(Tenant $tenant): void
    {
        $this->tenant = $tenant;

        setPermissionsTeamId($tenant->id);
    }

    public function forget(): void
    {
        $this->tenant = null;

        setPermissionsTeamId(null);
    }

    public function tenant(): ?Tenant
    {
        return $this->tenant;
    }

    public function id(): ?string
    {
        return $this->tenant?->id;
    }

    /**
     * @throws TenancyException
     */
    public function idOrFail(): string
    {
        return $this->id() ?? throw TenancyException::missingContext();
    }

    /**
     * Run the callback with the given tenant as current, then restore the previous tenant.
     *
     * @template TReturn
     *
     * @param  callable(): TReturn  $callback
     * @return TReturn
     */
    public function run(Tenant $tenant, callable $callback): mixed
    {
        $previous = $this->tenant;

        $this->set($tenant);

        try {
            return $callback();
        } finally {
            $previous === null ? $this->forget() : $this->set($previous);
        }
    }
}
