<?php

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\Models\ServiceCategory;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * Creates or edits a simple named catalog entry (a vehicle size or a service category).
 * New entries go to the end of their list unless placed explicitly.
 */
class SaveCatalogEntry
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  class-string<VehicleSize|ServiceCategory>  $modelClass
     * @param  array{name: string, sort_order?: int, is_active?: bool}  $data
     */
    public function create(User $actor, string $modelClass, array $data): VehicleSize|ServiceCategory
    {
        $entry = $modelClass::create([
            'sort_order' => ($modelClass::query()->max('sort_order') ?? -1) + 1,
            ...$data,
        ]);

        $this->auditTrail->record($this->event($entry, 'created'), $entry, $actor, 'Catalog entry added', ['name' => $entry->name]);

        return $entry;
    }

    /**
     * @param  array{name?: string, sort_order?: int, is_active?: bool}  $data
     */
    public function update(User $actor, VehicleSize|ServiceCategory $entry, array $data): VehicleSize|ServiceCategory
    {
        $entry->fill($data);
        $changes = array_keys($entry->getDirty());

        if ($changes !== []) {
            $entry->save();

            $this->auditTrail->record($this->event($entry, 'updated'), $entry, $actor, 'Catalog entry updated', ['changed' => $changes]);
        }

        return $entry;
    }

    private function event(Model $entry, string $verb): string
    {
        return ($entry instanceof VehicleSize ? 'vehicle_size' : 'service_category').".{$verb}";
    }
}
