<?php

namespace App\Http\Middleware;

use App\Domain\Platform\Tenancy\TenantContext;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Sets the current tenant from the authenticated user, never from request input.
 *
 * Runs after authentication and before route model binding (see the middleware priority in bootstrap/app.php).
 */
class SetTenantContext
{
    public function __construct(private TenantContext $tenantContext) {}

    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user === null) {
            return $next($request);
        }

        $tenant = $user->tenant;

        abort_if($tenant === null, Response::HTTP_FORBIDDEN, __('This account is not linked to a car wash.'));
        abort_unless($tenant->isActive(), Response::HTTP_FORBIDDEN, __('This car wash account is suspended.'));

        $this->tenantContext->set($tenant);

        return $next($request);
    }
}
