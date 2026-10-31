<?php

namespace App\Http\Exceptions;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

/**
 * Rewrites API error responses as RFC 9457 (formerly 7807) problem details:
 *
 *   {"type": "urn:carwash:problem:validation-failed", "title": "...", "status": 422,
 *    "detail": "...", "instance": "/api/v1/roles", "errors": {...}}
 *
 * Clients branch on "type"; "title" and "detail" are translated for display. Validation errors keep
 * Laravel's "errors" map, rate limits add "retry_after", and debug mode adds a "debug" block.
 */
class ProblemDetails
{
    public const CONTENT_TYPE = 'application/problem+json';

    public const TYPE_PREFIX = 'urn:carwash:problem:';

    /**
     * Problem type slug and English title (the translation key) per HTTP status.
     *
     * @var array<int, array{string, string}>
     */
    private const PROBLEMS = [
        401 => ['unauthenticated', 'Authentication required'],
        403 => ['forbidden', 'Access denied'],
        404 => ['not-found', 'Not found'],
        405 => ['method-not-allowed', 'Method not allowed'],
        409 => ['conflict', 'Conflict'],
        422 => ['validation-failed', 'The given data was invalid'],
        429 => ['too-many-requests', 'Too many requests'],
        500 => ['server-error', 'Server error'],
        503 => ['service-unavailable', 'Service unavailable'],
    ];

    public static function from(Response $response, Throwable $exception, Request $request): Response
    {
        if (! $response instanceof JsonResponse || $response->getStatusCode() < 400) {
            return $response;
        }

        $status = $response->getStatusCode();
        $original = $response->getData(true);
        [$slug, $title] = self::PROBLEMS[$status] ?? [null, Response::$statusTexts[$status] ?? 'Error'];

        $problem = [
            'type' => $slug === null ? 'about:blank' : self::TYPE_PREFIX.$slug,
            'title' => __($title),
            'status' => $status,
            'detail' => self::detail($status, $original['message'] ?? null, $title),
            'instance' => '/'.$request->path(),
        ];

        if (isset($original['errors'])) {
            $problem['errors'] = $original['errors'];
        }

        if ($response->headers->has('Retry-After')) {
            $problem['retry_after'] = (int) $response->headers->get('Retry-After');
        }

        if (config('app.debug') && isset($original['exception'])) {
            $problem['debug'] = array_intersect_key($original, array_flip(['exception', 'file', 'line', 'trace']));
        }

        $problemResponse = new JsonResponse($problem, $status, $response->headers->all());
        $problemResponse->headers->set('Content-Type', self::CONTENT_TYPE);

        return $problemResponse;
    }

    /**
     * Never leak internals: 404s hide which model was looked up, and 500s hide the exception outside debug mode.
     */
    private static function detail(int $status, ?string $message, string $title): string
    {
        return match (true) {
            $status === 404 => __('The requested resource was not found.'),
            $status >= 500 && ! config('app.debug') => __('Something went wrong on our side. Please try again.'),
            $message === null || $message === '' => __($title),
            default => __($message),
        };
    }
}
