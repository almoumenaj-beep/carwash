<?php

namespace App\Domain\Platform\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Opens a new branch. A creator limited to specific branches is given access to it,
 * so they do not lose sight of what they just created.
 */
class CreateBranch
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{name: string, code: string, phone?: ?string, address?: ?string, opening_hours?: array<string, mixed>}  $data
     */
    public function handle(User $actor, array $data): Branch
    {
        return DB::transaction(function () use ($actor, $data): Branch {
            $branch = Branch::create([
                ...$data,
                'opening_hours' => $data['opening_hours'] ?? Branch::defaultOpeningHours(),
            ]);

            if (! $actor->hasAllBranchAccess()) {
                $actor->branches()->attach($branch);
            }

            $this->auditTrail->record('branch.created', $branch, $actor, 'Branch opened', [
                'name' => $branch->name,
                'code' => $branch->code,
            ]);

            return $branch;
        });
    }
}
