<?php

namespace App\Domain\Identity\Models;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Policies\RolePolicy;
use App\Models\User;
use Illuminate\Database\Eloquent\Attributes\Scope;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\MorphToMany;
use Spatie\Permission\Models\Role as SpatieRole;

/**
 * A tenant's role. Not tenant-scoped by a global scope because spatie/permission loads roles
 * across teams for its cache; RolePolicy and the roles API constrain by tenant explicitly.
 */
#[UsePolicy(RolePolicy::class)]
class Role extends SpatieRole
{
    /**
     * Roles and permissions always use the web guard, even while a request is authenticated through
     * Sanctum (which switches the default guard to one without a user provider).
     */
    public const GUARD_NAME = 'web';

    /**
     * Staff holding this role. Overrides spatie's version, which resolves the model from the default guard.
     *
     * @return MorphToMany<User, $this>
     */
    public function users(): MorphToMany
    {
        return $this->morphedByMany(
            User::class,
            'model',
            config('permission.table_names.model_has_roles'),
            config('permission.column_names.role_pivot_key') ?? 'role_id',
            config('permission.column_names.model_morph_key'),
        );
    }

    public function defaultRole(): ?DefaultRole
    {
        return $this->key === null ? null : DefaultRole::tryFrom($this->key);
    }

    public function isOwnerRole(): bool
    {
        return $this->defaultRole() === DefaultRole::Owner;
    }

    /**
     * The name to show: default roles that were never renamed are translated, anything else is shown as named.
     */
    public function label(): string
    {
        $defaultRole = $this->defaultRole();

        if ($defaultRole !== null && $this->name === $defaultRole->displayName()) {
            return __("roles.{$defaultRole->value}");
        }

        return $this->name;
    }

    /**
     * @param  Builder<self>  $query
     */
    #[Scope]
    protected function ofTenant(Builder $query, ?string $tenantId): void
    {
        $query->where('tenant_id', $tenantId);
    }
}
