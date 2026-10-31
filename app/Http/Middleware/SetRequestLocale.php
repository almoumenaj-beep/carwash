<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Uses the Accept-Language header sent by the app to pick Arabic or English for messages and labels.
 */
class SetRequestLocale
{
    /**
     * @var list<string>
     */
    public const SUPPORTED_LOCALES = ['ar', 'en'];

    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->headers->has('Accept-Language')) {
            app()->setLocale($request->getPreferredLanguage(self::SUPPORTED_LOCALES));
        }

        return $next($request);
    }
}
