<?php

namespace App\Providers;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Domain\Platform\Tenancy\TenantContext;
use App\Models\User;
use Dedoc\Scramble\Scramble;
use Dedoc\Scramble\Support\Generator\OpenApi;
use Dedoc\Scramble\Support\Generator\SecurityScheme;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

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

        $this->configureSignInRateLimits();

        Scramble::configure()->withDocumentTransformers(function (OpenApi $openApi): void {
            $openApi->secure(SecurityScheme::http('bearer'));
        });
    }

    /**
     * Throttle guessing: passwords per account and IP, PINs per device, account and IP.
     */
    private function configureSignInRateLimits(): void
    {
        RateLimiter::for('login', fn (Request $request) => Limit::perMinute(5)
            ->by(Str::lower((string) $request->input('login')).'|'.$request->ip()));

        RateLimiter::for('pin-login', fn (Request $request) => Limit::perMinute(5)
            ->by($request->input('device_identifier').'|'.$request->input('user_id').'|'.$request->ip()));

        RateLimiter::for('device', fn (Request $request) => Limit::perMinute(30)
            ->by($request->input('device_identifier').'|'.$request->ip()));
    }
}
