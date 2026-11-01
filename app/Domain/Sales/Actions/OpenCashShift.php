<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Domain\Sales\Models\CashShift;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Opens a cashier's shift at a branch with the cash float counted into the drawer. A cashier has at
 * most one open shift per branch.
 */
class OpenCashShift
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Branch $branch, int $openingFloat): CashShift
    {
        return DB::transaction(function () use ($actor, $branch, $openingFloat): CashShift {
            User::query()->whereKey($actor->id)->lockForUpdate()->first();

            if (CashShift::openFor($actor, $branch) !== null) {
                throw ValidationException::withMessages(['shift' => __('You already have an open shift at this branch.')]);
            }

            $shift = new CashShift;
            $shift->forceFill([
                'branch_id' => $branch->id,
                'opened_by' => $actor->id,
                'opening_float' => $openingFloat,
                'opened_at' => now(),
            ])->save();

            $this->auditTrail->record('cash_shift.opened', $shift, $actor, 'Shift opened', ['opening_float' => $openingFloat]);

            return $shift;
        });
    }
}
