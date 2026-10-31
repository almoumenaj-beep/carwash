<?php

namespace App\Providers;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->scoped(TenantContext::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Owners hold every catalog permission. Limited to catalog abilities so policy rules
        // (such as "the owner role cannot be edited") still apply to owners.
        Gate::before(function (User $user, string $ability): ?bool {
            return Permission::tryFrom($ability) !== null && $user->isOwner() ? true : null;
        });

        // Roles and users are not tenant-scoped models, so bind them within the current tenant:
        // another tenant's record is a 404 and its existence is never revealed.
        Route::bind('role', fn (string $value) => Role::query()
            ->ofTenant($this->app->make(TenantContext::class)->idOrFail())
            ->findOrFail($value));

        Route::bind('user', fn (string $value) => User::query()
            ->where('tenant_id', $this->app->make(TenantContext::class)->idOrFail())
            ->findOrFail($value));
    }
}
