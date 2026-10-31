<?php

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\ServiceCategory;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Deletes catalog entries that nothing depends on:
 * - a vehicle size, with its prices (never the last size);
 * - a category, leaving its services uncategorised;
 * - a service, with its prices, unless it is in use (then it is deactivated instead).
 */
class DeleteCatalogEntry
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, VehicleSize|ServiceCategory|Service $entry): void
    {
        if ($entry instanceof VehicleSize && VehicleSize::query()->whereKeyNot($entry->getKey())->doesntExist()) {
            throw ValidationException::withMessages(['vehicle_size' => __('A car wash needs at least one vehicle size.')]);
        }

        if ($entry instanceof Service && $entry->isInUse()) {
            throw ValidationException::withMessages(['service' => __('This service has been sold. Deactivate it instead of deleting it.')]);
        }

        $event = match (true) {
            $entry instanceof VehicleSize => 'vehicle_size.deleted',
            $entry instanceof ServiceCategory => 'service_category.deleted',
            default => 'service.deleted',
        };

        DB::transaction(function () use ($actor, $entry, $event): void {
            $this->auditTrail->record($event, $entry, $actor, 'Catalog entry deleted', ['name' => $entry->name]);

            $entry->delete();
        });
    }
}
