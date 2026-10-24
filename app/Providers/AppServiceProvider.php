<?php

namespace App\Providers;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Illuminate\Support\Facades\Gate;
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
    }
}
