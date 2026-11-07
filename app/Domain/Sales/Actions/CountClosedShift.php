<?php

namespace App\Domain\Sales\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Sales\Models\CashShift;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Records the cash actually counted for a shift the system closed by itself, against what was expected
 * then. Counted once; a drawer that does not match needs a note.
 */
class CountClosedShift
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, CashShift $shift, int $countedCash, ?string $note): CashShift
    {
        return DB::transaction(function () use ($actor, $shift, $countedCash, $note): CashShift {
            $shift = CashShift::query()->whereKey($shift->getKey())->lockForUpdate()->firstOrFail();

            if (! $shift->awaitsCount()) {
                throw ValidationException::withMessages(['shift' => __('This shift is not waiting to be counted.')]);
            }

            $variance = $countedCash - $shift->expected_cash;

            if ($variance !== 0 && blank($note)) {
                throw ValidationException::withMessages(['note' => __('The drawer does not match; explain the difference.')]);
            }

            $shift->forceFill([
                'counted_cash' => $countedCash,
                'variance' => $variance,
                'close_note' => blank($note) ? null : $note,
                'counted_by' => $actor->id,
                'counted_at' => now(),
            ])->save();

            $this->auditTrail->record('cash_shift.counted', $shift, $actor, 'Automatically closed shift counted', [
                'expected_cash' => $shift->expected_cash,
                'counted_cash' => $countedCash,
                'variance' => $variance,
            ]);

            return $shift;
        });
    }
}
