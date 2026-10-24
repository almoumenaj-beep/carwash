<?php

namespace App\Domain\Platform\Tenancy;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

/**
 * Limits every query to the current tenant, and fails closed when no tenant is set.
 */
class TenantScope implements Scope
{
    /**
     * Apply the scope to a given Eloquent query builder.
     *
     * @throws TenancyException
     */
    public function apply(Builder $builder, Model $model): void
    {
        $builder->where($model->qualifyColumn('tenant_id'), app(TenantContext::class)->idOrFail());
    }
}
