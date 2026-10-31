<?php

namespace App\Domain\Platform\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Bay;
use App\Domain\Platform\Models\Branch;
use App\Models\User;

/**
 * Adds a bay to a branch or edits one. New bays go to the end of the branch's list unless placed explicitly.
 */
class SaveBay
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{name?: string, sort_order?: int, is_active?: bool}  $data
     */
    public function create(User $actor, Branch $branch, array $data): Bay
    {
        $bay = $branch->bays()->create([
            'sort_order' => ($branch->bays()->max('sort_order') ?? -1) + 1,
            ...$data,
        ]);

        $this->auditTrail->record('bay.created', $bay, $actor, 'Bay added', ['name' => $bay->name, 'branch_id' => $branch->id]);

        return $bay;
    }

    /**
     * @param  array{name?: string, sort_order?: int, is_active?: bool}  $data
     */
    public function update(User $actor, Bay $bay, array $data): Bay
    {
        $bay->fill($data);
        $changes = array_keys($bay->getDirty());

        if ($changes !== []) {
            $bay->save();

            $this->auditTrail->record('bay.updated', $bay, $actor, 'Bay updated', ['changed' => $changes]);
        }

        return $bay;
    }
}
