<?php

namespace App\Domain\Platform\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Models\User;

/**
 * Edits a branch's details, hours or activation. Branches are closed rather than deleted,
 * because orders and payments refer to them.
 */
class UpdateBranch
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{name?: string, code?: string, phone?: ?string, address?: ?string, opening_hours?: array<string, mixed>, is_active?: bool}  $data
     */
    public function handle(User $actor, Branch $branch, array $data): Branch
    {
        $branch->fill($data);
        $changes = array_keys($branch->getDirty());

        if ($changes !== []) {
            $branch->save();

            $this->auditTrail->record('branch.updated', $branch, $actor, 'Branch updated', ['changed' => $changes]);
        }

        return $branch;
    }
}
