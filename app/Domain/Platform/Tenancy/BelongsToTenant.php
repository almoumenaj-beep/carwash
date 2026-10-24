<?php

namespace App\Domain\Platform\Tenancy;

use App\Domain\Platform\Models\Tenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Isolates a model per tenant: reads are filtered by TenantScope, new records take the
 * current tenant, and records can never be written to or moved between other tenants.
 *
 * Creating with an explicit tenant_id and no current tenant is allowed for platform-level
 * code such as seeders and onboarding.
 */
trait BelongsToTenant
{
    public static function bootBelongsToTenant(): void
    {
        static::addGlobalScope(new TenantScope);

        static::creating(function (Model $model): void {
            $currentTenantId = app(TenantContext::class)->id();

            if ($model->tenant_id === null) {
                $model->tenant_id = $currentTenantId ?? throw TenancyException::missingContext();
            } elseif ($currentTenantId !== null && $model->tenant_id !== $currentTenantId) {
                throw TenancyException::crossTenantWrite($model::class);
            }
        });

        static::updating(function (Model $model): void {
            if ($model->isDirty('tenant_id')) {
                throw TenancyException::tenantChange($model::class);
            }
        });
    }

    /**
     * @return BelongsTo<Tenant, $this>
     */
    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
