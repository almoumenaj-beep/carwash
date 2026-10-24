<?php

namespace App\Domain\Identity\Models;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Policies\RolePolicy;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Spatie\Permission\Models\Role as SpatieRole;

/**
 * A tenant's role. Not tenant-scoped by a global scope because spatie/permission loads roles
 * across teams for its cache; RolePolicy and the roles API constrain by tenant explicitly.
 */
#[UsePolicy(RolePolicy::class)]
class Role extends SpatieRole
{
    public function defaultRole(): ?DefaultRole
    {
        return $this->key === null ? null : DefaultRole::tryFrom($this->key);
    }

    public function isOwnerRole(): bool
    {
        return $this->defaultRole() === DefaultRole::Owner;
    }
}
