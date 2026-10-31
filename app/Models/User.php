<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Policies\UserPolicy;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
#[UsePolicy(UserPolicy::class)]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, HasUuids, Notifiable;

    /**
     * The guard spatie/permission checks roles against, also during Sanctum-authenticated requests.
     */
    protected string $guard_name = Role::GUARD_NAME;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'all_branches' => 'boolean',
        ];
    }

    /**
     * Users are not tenant-scoped (authentication must find them before a tenant is known),
     * so queries listing users must constrain by tenant explicitly.
     *
     * @return BelongsTo<Tenant, $this>
     */
    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    /**
     * The branches this user works in, when not granted all branches.
     *
     * @return BelongsToMany<Branch, $this>
     */
    public function branches(): BelongsToMany
    {
        return $this->belongsToMany(Branch::class)->withTimestamps();
    }

    /**
     * Whether the user holds the owner role in the current tenant.
     */
    public function isOwner(): bool
    {
        return $this->roles->contains(fn ($role) => $role->key === DefaultRole::Owner->value);
    }

    public function hasAllBranchAccess(): bool
    {
        return $this->all_branches || $this->isOwner();
    }

    /**
     * Every permission the user holds in the current tenant; owners hold the whole catalog.
     *
     * @return list<string>
     */
    public function permissionNames(): array
    {
        if ($this->isOwner()) {
            return Permission::values();
        }

        return $this->getAllPermissions()->pluck('name')->sort()->values()->all();
    }

    /**
     * The branches the user may work in, ordered by name.
     *
     * @return Collection<int, Branch>
     */
    public function accessibleBranches(): Collection
    {
        $query = $this->hasAllBranchAccess() ? Branch::query() : $this->branches();

        return $query->orderBy('name')->get();
    }

    public function canAccessBranch(Branch $branch): bool
    {
        if ($branch->tenant_id !== $this->tenant_id) {
            return false;
        }

        return $this->hasAllBranchAccess() || $this->branches()->whereKey($branch->getKey())->exists();
    }
}
