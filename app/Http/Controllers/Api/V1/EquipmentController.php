<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Equipment\Actions\CancelMaintenance;
use App\Domain\Equipment\Actions\RecordMaintenance;
use App\Domain\Equipment\Actions\ReportBreakdown;
use App\Domain\Equipment\Enums\EquipmentStatus;
use App\Domain\Equipment\Models\Equipment;
use App\Domain\Equipment\Models\EquipmentBreakdown;
use App\Domain\Equipment\Models\EquipmentMaintenance;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveEquipmentRequest;
use App\Http\Requests\StoreBreakdownRequest;
use App\Http\Requests\StoreMaintenanceRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Equipment at the user's branches with its maintenance schedule and history. Seen with equipment.view;
 * equipment is added, edited and maintained with equipment.manage.
 */
class EquipmentController extends Controller
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * Equipment at a branch (or at every branch the user works in): what is due for maintenance first,
     * retired equipment last. `meta.due_count` is how many are due today or overdue.
     */
    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::EquipmentView->value);
        $request->validate(['branch_id' => ['sometimes', 'nullable', 'uuid']]);

        if ($request->filled('branch_id')) {
            $branch = Branch::query()->findOrFail($request->input('branch_id'));
            Gate::authorize('view', $branch);
            $branchIds = [$branch->id];
        } else {
            $branchIds = $request->user()->accessibleBranches()->modelKeys();
        }

        $today = $this->today($request);
        $equipment = Equipment::query()->whereIn('branch_id', $branchIds)->with(['branch', 'latestBreakdown'])->orderBy('name')->get()
            ->sortBy(fn (Equipment $item) => [
                $item->status === EquipmentStatus::Retired ? 1 : 0,
                $item->daysUntilMaintenance($today) ?? PHP_INT_MAX,
            ])
            ->values();

        return response()->json([
            'data' => $equipment->map(fn (Equipment $item) => $this->present($item, $today)),
            'meta' => ['due_count' => $equipment->filter(fn (Equipment $item) => ($item->daysUntilMaintenance($today) ?? 1) <= 0)->count()],
        ]);
    }

    public function store(SaveEquipmentRequest $request): JsonResponse
    {
        $equipment = new Equipment($request->validated());
        $equipment->scheduleNextMaintenance($this->today($request));
        $equipment->save();
        $this->auditTrail->record('equipment.created', $equipment, $request->user(), 'Equipment added', ['name' => $equipment->name]);

        return response()->json(['data' => $this->present($equipment->load('branch'), $this->today($request))], Response::HTTP_CREATED);
    }

    public function update(SaveEquipmentRequest $request, Equipment $equipment): JsonResponse
    {
        $equipment->fill($request->validated());
        if ($equipment->isDirty(['maintenance_interval_days', 'purchased_on'])) {
            $equipment->scheduleNextMaintenance($this->today($request));
        }
        $equipment->save();
        $this->auditTrail->record('equipment.updated', $equipment, $request->user(), 'Equipment updated', ['changed' => array_keys($equipment->getChanges())]);

        return response()->json(['data' => $this->present($equipment->load('branch'), $this->today($request))]);
    }

    /**
     * The equipment's maintenance, latest first.
     */
    public function maintenances(Request $request, Equipment $equipment): JsonResponse
    {
        Gate::authorize(Permission::EquipmentView->value);
        Gate::authorize('view', $equipment->branch);

        $maintenances = $equipment->maintenances()->with(['supplier', 'expense', 'creator', 'canceller'])->latest('performed_on')->latest()->get();

        return response()->json(['data' => $maintenances->map($this->presentMaintenance(...))]);
    }

    /**
     * The times the equipment was reported broken, latest first.
     */
    public function breakdowns(Request $request, Equipment $equipment): JsonResponse
    {
        Gate::authorize(Permission::EquipmentView->value);
        Gate::authorize('view', $equipment->branch);

        $breakdowns = $equipment->breakdowns()->with('reporter')->latest('reported_at')->get();

        return response()->json(['data' => $breakdowns->map($this->presentBreakdown(...))]);
    }

    /**
     * Report equipment in service as broken, with the reason.
     */
    public function reportBreakdown(StoreBreakdownRequest $request, Equipment $equipment, ReportBreakdown $reportBreakdown): JsonResponse
    {
        $breakdown = $reportBreakdown->handle($request->user(), $equipment, $request->validated('reason'));

        return response()->json([
            'data' => $this->presentBreakdown($breakdown->load('reporter')),
            'equipment' => $this->present($equipment->fresh()->load('branch'), $this->today($request)),
        ], Response::HTTP_CREATED);
    }

    public function maintain(StoreMaintenanceRequest $request, Equipment $equipment, RecordMaintenance $recordMaintenance): JsonResponse
    {
        $maintenance = $recordMaintenance->handle($request->user(), $equipment, $request->validated());

        return response()->json([
            'data' => $this->presentMaintenance($maintenance->load(['supplier', 'expense', 'creator'])),
            'equipment' => $this->present($equipment->load('branch'), $this->today($request)),
        ], Response::HTTP_CREATED);
    }

    /**
     * Cancel maintenance recorded by mistake. If its cost was already paid, that takes money back out of the
     * books, so it also needs expenses.approve.
     */
    public function cancelMaintenance(Request $request, Equipment $equipment, EquipmentMaintenance $maintenance, CancelMaintenance $cancelMaintenance): JsonResponse
    {
        abort_unless($maintenance->equipment_id === $equipment->id, Response::HTTP_NOT_FOUND);
        Gate::authorize(Permission::EquipmentManage->value);
        Gate::authorize('view', $equipment->branch);

        if ($maintenance->expense?->isPaid()) {
            Gate::authorize(Permission::ExpensesApprove->value);
        }

        $maintenance = $cancelMaintenance->handle($request->user(), $maintenance);

        return response()->json([
            'data' => $this->presentMaintenance($maintenance->load(['supplier', 'expense', 'creator', 'canceller'])),
            'equipment' => $this->present($equipment->refresh()->load('branch'), $this->today($request)),
        ]);
    }

    private function today(Request $request): CarbonImmutable
    {
        return CarbonImmutable::now($request->user()->tenant->timezone)->startOfDay();
    }

    /**
     * @return array<string, mixed>
     */
    private function present(Equipment $equipment, CarbonImmutable $today): array
    {
        $days = $equipment->daysUntilMaintenance($today);

        return [
            'id' => $equipment->id,
            'branch' => ['id' => $equipment->branch->id, 'name' => $equipment->branch->name],
            'name' => $equipment->name,
            'serial_number' => $equipment->serial_number,
            'purchased_on' => $equipment->purchased_on?->toDateString(),
            'purchase_cost' => $equipment->purchase_cost,
            'status' => $equipment->status,
            'maintenance_interval_days' => $equipment->maintenance_interval_days,
            'last_maintained_on' => $equipment->last_maintained_on?->toDateString(),
            'next_maintenance_on' => $equipment->next_maintenance_on?->toDateString(),
            'days_until_maintenance' => $days,
            'is_due' => $days !== null && $days <= 0,
            'notes' => $equipment->notes,
            'breakdown_reason' => $equipment->status === EquipmentStatus::OutOfService ? $equipment->latestBreakdown?->reason : null,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function presentBreakdown(EquipmentBreakdown $breakdown): array
    {
        return [
            'id' => $breakdown->id,
            'reason' => $breakdown->reason,
            'reported_at' => $breakdown->reported_at->toIso8601String(),
            'reported_by' => ['id' => $breakdown->reporter->id, 'name' => $breakdown->reporter->name],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function presentMaintenance(EquipmentMaintenance $maintenance): array
    {
        return [
            'id' => $maintenance->id,
            'kind' => $maintenance->kind,
            'performed_on' => $maintenance->performed_on->toDateString(),
            'description' => $maintenance->description,
            'cost' => $maintenance->cost,
            'supplier' => $maintenance->supplier === null ? null : ['id' => $maintenance->supplier->id, 'name' => $maintenance->supplier->name],
            'is_paid' => $maintenance->expense?->isPaid() ?? true,
            'is_cancelled' => $maintenance->isCancelled(),
            'cancelled_by' => $maintenance->canceller?->name,
            'created_by' => ['id' => $maintenance->creator->id, 'name' => $maintenance->creator->name],
        ];
    }
}
