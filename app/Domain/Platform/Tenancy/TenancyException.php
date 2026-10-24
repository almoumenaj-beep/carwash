<?php

namespace App\Domain\Platform\Tenancy;

use RuntimeException;

/**
 * Raised when code would read or write tenant data outside of the current tenant.
 */
class TenancyException extends RuntimeException
{
    public static function missingContext(): self
    {
        return new self('No tenant is set for the current context. Set one through TenantContext or remove the TenantScope explicitly.');
    }

    public static function crossTenantWrite(string $modelClass): self
    {
        return new self("Refusing to create [{$modelClass}] for a tenant other than the current tenant.");
    }

    public static function tenantChange(string $modelClass): self
    {
        return new self("The tenant of an existing [{$modelClass}] cannot be changed.");
    }
}
