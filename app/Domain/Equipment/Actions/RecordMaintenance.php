<?php

namespace App\Domain\Equipment\Actions;

use App\Domain\Equipment\Enums\EquipmentStatus;
use App\Domain\Equipment\Enums\MaintenanceKind;
use App\Domain\Equipment\Models\Equipment;
use App\Domain\Equipment\Models\EquipmentMaintenance;
use App\Domain\Expenses\Actions\RecordExpense;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Records maintenance done on a piece of equipment. Its cost becomes an expense of the equipment's branch
 * (paid, or owed to the supplier when no payment method is given); periodic maintenance restarts the
 * schedule, and a repair puts broken equipment back in service.
 */
class RecordMaintenance
{
    public function __construct(private RecordExpense $recordExpense, private AuditTrail $auditTrail) {}

    /**
     * @param  array{kind: string, performed_on?: ?string, description?: ?string, cost?: ?int, supplier_id?: ?string, expense_category_id?: ?string, payment_method?: ?string}  $data
     *
     * @throws ValidationException
     */
    public function handle(User $actor, Equipment $equipment, array $data): EquipmentMaintenance
    {
        $today = CarbonImmutable::now($actor->tenant->timezone)->startOfDay();
        $kind = MaintenanceKind::from($data['kind']);
        $performedOn = CarbonImmutable::parse($data['performed_on'] ?? $today->toDateString());
        $cost = (int) ($data['cost'] ?? 0);

        return DB::transaction(function () use ($actor, $equipment, $data, $today, $kind, $performedOn, $cost): EquipmentMaintenance {
            $expense = $cost === 0 ? null : $this->recordExpense->handle($actor, [
                'branch_id' => $equipment->branch_id,
                'expense_category_id' => $data['expense_category_id'],
                'supplier_id' => $data['supplier_id'] ?? null,
                'amount' => $cost,
                'spent_on' => $performedOn->toDateString(),
                'description' => __('Maintenance: :name', ['name' => $equipment->name]),
                'payment_method' => $data['payment_method'] ?? null,
            ]);

            $putBackInService = $kind === MaintenanceKind::Repair && $equipment->status === EquipmentStatus::OutOfService;

            $maintenance = new EquipmentMaintenance;
            $maintenance->forceFill([
                'equipment_id' => $equipment->id,
                'kind' => $kind,
                'performed_on' => $performedOn->toDateString(),
                'description' => $data['description'] ?? null,
                'cost' => $cost,
                'supplier_id' => $data['supplier_id'] ?? null,
                'expense_id' => $expense?->id,
                'put_back_in_service' => $putBackInService,
                'created_by' => $actor->id,
            ])->save();

            if ($kind === MaintenanceKind::Periodic && ($equipment->last_maintained_on === null || $performedOn->toDateString() >= $equipment->last_maintained_on->toDateString())) {
                $equipment->last_maintained_on = $performedOn;
                $equipment->scheduleNextMaintenance($today);
            }
            if ($putBackInService) {
                $equipment->status = EquipmentStatus::InService;
            }
            $equipment->save();

            $this->auditTrail->record('equipment.maintained', $maintenance, $actor, 'Maintenance recorded', [
                'equipment_id' => $equipment->id,
                'kind' => $kind->value,
                'cost' => $cost,
            ]);

            return $maintenance;
        });
    }
}
