<?php

namespace App\Domain\Equipment\Actions;

use App\Domain\Equipment\Enums\EquipmentStatus;
use App\Domain\Equipment\Enums\MaintenanceKind;
use App\Domain\Equipment\Models\Equipment;
use App\Domain\Equipment\Models\EquipmentMaintenance;
use App\Domain\Expenses\Actions\DeleteExpense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Cancels maintenance recorded by mistake: its expense is removed and it stays on record as cancelled. Periodic
 * maintenance gives the schedule back to the last one still standing; a repair that brought broken equipment back
 * leaves it broken again.
 */
class CancelMaintenance
{
    public function __construct(private DeleteExpense $deleteExpense, private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, EquipmentMaintenance $maintenance): EquipmentMaintenance
    {
        return DB::transaction(function () use ($actor, $maintenance): EquipmentMaintenance {
            $maintenance = EquipmentMaintenance::query()->with('expense.cashShift')->lockForUpdate()->findOrFail($maintenance->id);

            if ($maintenance->isCancelled()) {
                throw ValidationException::withMessages(['maintenance' => __('This maintenance was already cancelled.')]);
            }

            if ($maintenance->expense !== null) {
                $this->deleteExpense->remove($actor, $maintenance->expense);
            }

            $maintenance->forceFill(['cancelled_at' => now(), 'cancelled_by' => $actor->id, 'expense_id' => null])->save();
            $this->undoOnEquipment($actor, $maintenance, $maintenance->equipment);

            $this->auditTrail->record('equipment.maintenance_cancelled', $maintenance, $actor, 'Maintenance cancelled', [
                'equipment_id' => $maintenance->equipment_id,
                'cost' => $maintenance->cost,
            ]);

            return $maintenance;
        });
    }

    private function undoOnEquipment(User $actor, EquipmentMaintenance $maintenance, Equipment $equipment): void
    {
        if ($maintenance->kind === MaintenanceKind::Periodic) {
            $last = $equipment->maintenances()
                ->where('kind', MaintenanceKind::Periodic)
                ->whereNull('cancelled_at')
                ->max('performed_on');

            $equipment->last_maintained_on = $last === null ? null : CarbonImmutable::parse($last);
            $equipment->scheduleNextMaintenance(CarbonImmutable::now($actor->tenant->timezone)->startOfDay());
        }

        if ($maintenance->put_back_in_service && $equipment->status === EquipmentStatus::InService) {
            $equipment->status = EquipmentStatus::OutOfService;
        }

        $equipment->save();
    }
}
