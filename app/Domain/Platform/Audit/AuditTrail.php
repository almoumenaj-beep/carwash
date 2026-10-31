<?php

namespace App\Domain\Platform\Audit;

use App\Domain\Platform\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Model;

/**
 * Records sensitive changes (permissions, prices, refunds, ...) in the activity log,
 * stamped with the current tenant so each car wash sees only its own trail.
 */
class AuditTrail
{
    public const LOG_NAME = 'audit';

    public function __construct(private TenantContext $tenantContext) {}

    /**
     * @param  array<string, mixed>  $properties
     */
    public function record(string $event, Model $subject, ?Model $causer, string $description, array $properties = []): void
    {
        activity(self::LOG_NAME)
            ->performedOn($subject)
            ->causedBy($causer)
            ->event($event)
            ->withProperties($properties)
            ->tap(function (Model $activity): void {
                $activity->setAttribute('tenant_id', $this->tenantContext->id());
            })
            ->log($description);
    }
}
