<?php

namespace App\Domain\Equipment\Actions;

use App\Domain\Equipment\Enums\EquipmentStatus;
use App\Domain\Equipment\Models\Equipment;
use App\Domain\Equipment\Models\EquipmentBreakdown;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Reports equipment in service as broken, with the reason, which stays in its history.
 */
class ReportBreakdown
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Equipment $equipment, string $reason): EquipmentBreakdown
    {
        return DB::transaction(function () use ($actor, $equipment, $reason): EquipmentBreakdown {
            $equipment = Equipment::query()->whereKey($equipment->getKey())->lockForUpdate()->firstOrFail();

            if ($equipment->status !== EquipmentStatus::InService) {
                throw ValidationException::withMessages(['equipment' => __('Only equipment in service can be reported broken.')]);
            }

            $equipment->status = EquipmentStatus::OutOfService;
            $equipment->save();

            $breakdown = new EquipmentBreakdown;
            $breakdown->forceFill([
                'equipment_id' => $equipment->id,
                'reason' => $reason,
                'reported_by' => $actor->id,
                'reported_at' => now(),
            ])->save();

            $this->auditTrail->record('equipment.broke_down', $equipment, $actor, 'Equipment reported broken', ['reason' => $reason]);

            return $breakdown;
        });
    }
}
