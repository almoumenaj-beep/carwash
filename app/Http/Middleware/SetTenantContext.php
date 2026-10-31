<?php

namespace App\Http\Middleware;

use App\Domain\Identity\Support\SignInEligibility;
use App\Domain\Platform\Tenancy\TenantContext;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Sets the current tenant from the authenticated user, never from request input, and rejects
 * users whose car wash is suspended or whose account is deactivated (403).
 *
 * Runs after authentication and before route model binding (see the middleware priority in bootstrap/app.php).
 */
class SetTenantContext
{
    public function __construct(private TenantContext $tenantContext, private SignInEligibility $signInEligibility) {}

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

        $this->signInEligibility->ensure($user);

        $this->tenantContext->set($user->tenant);

        return $next($request);
    }
}
