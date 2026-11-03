<?php

namespace Tests\Feature;

use App\Domain\Equipment\Models\Equipment;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Expenses\Models\Supplier;
use App\Domain\Identity\Enums\DefaultRole;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class EquipmentTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $manager;

    private ExpenseCategory $maintenance;

    private Supplier $technician;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo(CarbonImmutable::parse('2026-11-03 10:00', 'Asia/Bahrain'));
        $this->buildCarWash();
        $this->manager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->branch]);
        $this->inTenant(function (): void {
            $this->maintenance = ExpenseCategory::factory()->create(['name' => 'Maintenance and equipment']);
            $this->technician = Supplier::factory()->create(['name' => 'Kärcher service']);
        });
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    private function addEquipment(array $overrides = []): TestResponse
    {
        Sanctum::actingAs($this->manager);

        return $this->postJson('/api/v1/equipment', [
            'branch_id' => $this->branch->id,
            'name' => 'Pressure washer 1',
            'purchased_on' => '2026-10-01',
            'purchase_cost' => 450000,
            'maintenance_interval_days' => 30,
            ...$overrides,
        ]);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function maintain(string $equipmentId, array $data): TestResponse
    {
        Sanctum::actingAs($this->manager);

        return $this->postJson("/api/v1/equipment/{$equipmentId}/maintenances", $data);
    }

    public function test_periodic_maintenance_falls_due_an_interval_after_purchase_and_due_equipment_comes_first(): void
    {
        $this->addEquipment()
            ->assertCreated()
            ->assertJsonPath('data.next_maintenance_on', '2026-10-31')
            ->assertJsonPath('data.days_until_maintenance', -3)
            ->assertJsonPath('data.is_due', true);
        $this->addEquipment(['name' => 'Vacuum', 'purchased_on' => null, 'maintenance_interval_days' => 90])
            ->assertJsonPath('data.next_maintenance_on', '2027-02-01');
        $this->addEquipment(['name' => 'Old compressor', 'status' => 'retired']);
        $this->addEquipment(['name' => 'Bucket', 'maintenance_interval_days' => null])
            ->assertJsonPath('data.next_maintenance_on', null);

        $this->getJson('/api/v1/equipment')
            ->assertOk()
            ->assertJsonPath('meta.due_count', 1)
            ->assertJsonPath('data.*.name', ['Pressure washer 1', 'Vacuum', 'Bucket', 'Old compressor'])
            ->assertJsonPath('data.3.is_due', false);
    }

    public function test_periodic_maintenance_owed_to_a_supplier_is_an_expense_and_restarts_the_schedule(): void
    {
        $equipmentId = $this->addEquipment()->json('data.id');

        $this->maintain($equipmentId, [
            'kind' => 'periodic',
            'performed_on' => '2026-11-02',
            'description' => 'Oil and seals',
            'cost' => 15000,
            'supplier_id' => $this->technician->id,
            'expense_category_id' => $this->maintenance->id,
        ])
            ->assertCreated()
            ->assertJsonPath('data.is_paid', false)
            ->assertJsonPath('equipment.last_maintained_on', '2026-11-02')
            ->assertJsonPath('equipment.next_maintenance_on', '2026-12-02')
            ->assertJsonPath('equipment.is_due', false);

        $expense = $this->inTenant(fn () => Expense::query()->sole());
        $this->assertSame(15000, $expense->amount);
        $this->assertSame($this->technician->id, $expense->supplier_id);
        $this->assertSame($this->branch->id, $expense->branch_id);
        $this->assertNull($expense->paid_at);

        $this->maintain($equipmentId, ['kind' => 'periodic', 'performed_on' => '2026-10-20'])
            ->assertCreated()
            ->assertJsonPath('equipment.next_maintenance_on', '2026-12-02');
        $this->getJson("/api/v1/equipment/{$equipmentId}/maintenances")
            ->assertOk()
            ->assertJsonPath('data.*.performed_on', ['2026-11-02', '2026-10-20']);
        $this->assertSame(1, $this->inTenant(fn () => Expense::query()->count()), 'free maintenance records no expense');
    }

    public function test_a_repair_puts_broken_equipment_back_in_service_without_moving_the_schedule(): void
    {
        $equipmentId = $this->addEquipment()->json('data.id');
        $this->patchJson("/api/v1/equipment/{$equipmentId}", ['status' => 'out_of_service'])
            ->assertOk()
            ->assertJsonPath('data.status', 'out_of_service');

        $this->maintain($equipmentId, [
            'kind' => 'repair',
            'cost' => 8000,
            'expense_category_id' => $this->maintenance->id,
            'payment_method' => 'cash',
        ])
            ->assertCreated()
            ->assertJsonPath('data.is_paid', true)
            ->assertJsonPath('equipment.status', 'in_service')
            ->assertJsonPath('equipment.next_maintenance_on', '2026-10-31');
    }

    public function test_changing_the_interval_reschedules_from_the_last_maintenance(): void
    {
        $equipmentId = $this->addEquipment()->json('data.id');
        $this->maintain($equipmentId, ['kind' => 'periodic', 'performed_on' => '2026-11-01']);

        $this->patchJson("/api/v1/equipment/{$equipmentId}", ['maintenance_interval_days' => 7])
            ->assertOk()
            ->assertJsonPath('data.next_maintenance_on', '2026-11-08');
    }

    public function test_a_cost_needs_an_expense_category(): void
    {
        $equipmentId = $this->addEquipment()->json('data.id');

        $this->maintain($equipmentId, ['kind' => 'repair', 'cost' => 5000])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('expense_category_id');
    }

    public function test_equipment_is_kept_to_staff_with_the_permission_and_the_branch(): void
    {
        $equipmentId = $this->addEquipment()->json('data.id');
        $otherManager = $this->createStaff($this->tenant, DefaultRole::BranchManager, [$this->otherBranch]);

        Sanctum::actingAs($this->cashier);
        $this->getJson('/api/v1/equipment')->assertForbidden();

        Sanctum::actingAs($otherManager);
        $this->getJson('/api/v1/equipment')->assertOk()->assertJsonCount(0, 'data');
        $this->patchJson("/api/v1/equipment/{$equipmentId}", ['name' => 'Mine now'])->assertForbidden();
        $this->postJson("/api/v1/equipment/{$equipmentId}/maintenances", ['kind' => 'periodic'])->assertForbidden();
        $this->getJson("/api/v1/equipment/{$equipmentId}/maintenances")->assertForbidden();
        $this->postJson('/api/v1/equipment', ['branch_id' => $this->branch->id, 'name' => 'Sneaky'])->assertForbidden();

        $accountant = $this->createStaff($this->tenant, DefaultRole::Accountant, allBranches: true);
        Sanctum::actingAs($accountant);
        $this->getJson('/api/v1/equipment')->assertOk()->assertJsonCount(1, 'data');
        $this->patchJson("/api/v1/equipment/{$equipmentId}", ['name' => 'Renamed'])->assertForbidden();

        $this->assertSame('Pressure washer 1', $this->inTenant(fn () => Equipment::query()->sole()->name));
    }
}
