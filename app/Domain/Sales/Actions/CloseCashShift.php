<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Sales\Models\CashShift;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Closes a shift with the cash counted in the drawer: stores what was expected (float + cash taken)
 * and the variance. A drawer that does not match needs a note.
 */
class CloseCashShift
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, CashShift $shift, int $countedCash, ?string $note): CashShift
    {
        return DB::transaction(function () use ($actor, $shift, $countedCash, $note): CashShift {
            $shift = CashShift::query()->whereKey($shift->getKey())->lockForUpdate()->firstOrFail();

            if (! $shift->isOpen()) {
                throw ValidationException::withMessages(['shift' => __('This shift is already closed.')]);
            }

            $expected = $shift->expectedCash();
            $variance = $countedCash - $expected;

            if ($variance !== 0 && blank($note)) {
                throw ValidationException::withMessages(['note' => __('The drawer does not match; explain the difference.')]);
            }

            $shift->forceFill([
                'closed_by' => $actor->id,
                'closed_at' => now(),
                'expected_cash' => $expected,
                'counted_cash' => $countedCash,
                'variance' => $variance,
                'close_note' => blank($note) ? null : $note,
            ])->save();

            $this->auditTrail->record('cash_shift.closed', $shift, $actor, 'Shift closed', [
                'expected_cash' => $expected,
                'counted_cash' => $countedCash,
                'variance' => $variance,
            ]);

            return $shift;
        });
    }
}
