<?php

namespace Tests\Feature;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Expenses\Models\Supplier;
use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Inventory\Models\InventoryItem;
use App\Domain\Inventory\Models\Purchase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class InventoryTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private User $keeper;

    private User $owner;

    private InventoryItem $shampoo;

    private InventoryItem $towels;

    private ExpenseCategory $supplies;

    private Supplier $supplier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $this->keeper = $this->createStaff($this->tenant, DefaultRole::InventoryKeeper, [$this->branch]);
        $this->owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        $this->inTenant(function (): void {
            $this->shampoo = InventoryItem::factory()->create(['name' => 'Shampoo', 'unit' => 'L', 'min_stock_milli' => 2000]);
            $this->towels = InventoryItem::factory()->create(['name' => 'Towels', 'unit' => 'pc']);
            $this->supplies = ExpenseCategory::factory()->create(['name' => 'Cleaning supplies']);
            $this->supplier = Supplier::factory()->create(['name' => 'Gulf Chemicals']);
        });
    }

    /**
     * 10 litres of shampoo at 1.250 a litre and 100 towels at 0.050 each, owed to the supplier.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function purchase(array $overrides = []): TestResponse
    {
        Sanctum::actingAs($this->keeper);

        return $this->postJson('/api/v1/inventory/purchases', [
            'branch_id' => $this->branch->id,
            'supplier_id' => $this->supplier->id,
            'expense_category_id' => $this->supplies->id,
            'lines' => [
                ['inventory_item_id' => $this->shampoo->id, 'quantity' => 10, 'unit_cost' => 1250],
                ['inventory_item_id' => $this->towels->id, 'quantity' => 100, 'unit_cost' => 50],
            ],
            ...$overrides,
        ]);
    }

    /**
     * @return array<string, array<string, mixed>>
     */
    private function stockByName(?string $branchId = null): array
    {
        $query = $branchId === null ? '' : "?branch_id={$branchId}";

        return collect($this->getJson("/api/v1/inventory/items{$query}")->assertOk()->json('data'))->keyBy('name')->all();
    }

    public function test_a_purchase_adds_stock_updates_costs_and_is_owed_to_the_supplier(): void
    {
        $this->purchase()
            ->assertCreated()
            ->assertJsonPath('data.total', 17500)
            ->assertJsonPath('data.is_paid', false)
            ->assertJsonPath('data.lines.0.quantity', 10)
            ->assertJsonPath('data.supplier.name', 'Gulf Chemicals');

        $stock = $this->stockByName($this->branch->id);
        $this->assertEquals(10, $stock['Shampoo']['quantity']);
        $this->assertSame(1250, $stock['Shampoo']['unit_cost']);
        $this->assertEquals(100, $stock['Towels']['quantity']);
        $this->assertFalse($stock['Shampoo']['is_low']);

        $expense = $this->inTenant(fn () => Expense::query()->sole());
        $this->assertSame(17500, $expense->amount);
        $this->assertFalse($expense->isPaid());
        $this->assertSame($this->supplier->id, $expense->supplier_id);
    }

    public function test_starting_a_wash_uses_up_its_materials_once(): void
    {
        $this->purchase()->assertCreated();
        Sanctum::actingAs($this->owner);
        $this->putJson("/api/v1/services/{$this->wash->id}/materials", ['materials' => [
            ['inventory_item_id' => $this->shampoo->id, 'quantity' => 0.25],
            ['inventory_item_id' => $this->towels->id, 'quantity' => 2],
        ]])->assertOk()->assertJsonPath('data.0.quantity', 0.25);

        $orderId = $this->checkIn()->json('data.id');
        $this->moveTo($orderId, 'in_progress', $this->washer)->assertOk();
        $this->moveTo($orderId, 'qc', $this->washer)->assertOk();
        $this->moveTo($orderId, 'in_progress', $this->washer, ['checklist' => []])->assertOk();

        Sanctum::actingAs($this->keeper);
        $stock = $this->stockByName($this->branch->id);
        $this->assertEquals(9.75, $stock['Shampoo']['quantity']);
        $this->assertEquals(98, $stock['Towels']['quantity']);

        $this->getJson("/api/v1/inventory/movements?branch_id={$this->branch->id}&inventory_item_id={$this->shampoo->id}")
            ->assertJsonPath('data.0.reason', 'consumption')
            ->assertJsonPath('data.0.change', -0.25)
            ->assertJsonPath('data.0.balance', 9.75)
            ->assertJsonPath('data.0.order_id', $orderId)
            ->assertJsonCount(2, 'data');
    }

    public function test_a_package_uses_the_materials_of_its_services(): void
    {
        Sanctum::actingAs($this->owner);
        $this->putJson("/api/v1/services/{$this->wash->id}/materials", ['materials' => [
            ['inventory_item_id' => $this->shampoo->id, 'quantity' => 0.5],
        ]])->assertOk();
        $packageId = $this->postJson('/api/v1/services', [
            'name' => 'Combo',
            'is_package' => true,
            'package_discount_type' => 'amount',
            'package_discount_value' => 100,
            'package_service_ids' => [$this->wash->id, $this->freshener->id],
        ])->assertCreated()->json('data.id');
        $this->putJson("/api/v1/services/{$packageId}/materials", ['materials' => [
            ['inventory_item_id' => $this->towels->id, 'quantity' => 1],
        ]])->assertUnprocessable()->assertJsonValidationErrors('materials');

        $orderId = $this->checkIn(['items' => [['service_id' => $packageId]]])->json('data.id');
        $this->moveTo($orderId, 'in_progress', $this->washer)->assertOk();

        Sanctum::actingAs($this->keeper);
        $this->assertEquals(-0.5, $this->stockByName($this->branch->id)['Shampoo']['quantity']);
    }

    public function test_a_stock_count_records_the_difference(): void
    {
        $this->purchase()->assertCreated();

        $this->postJson('/api/v1/inventory/counts', [
            'branch_id' => $this->branch->id,
            'inventory_item_id' => $this->shampoo->id,
            'quantity' => 1.5,
            'note' => 'Monthly count',
        ])->assertOk()->assertJsonPath('data.quantity', 1.5)->assertJsonPath('data.is_low', true);

        $this->getJson("/api/v1/inventory/movements?branch_id={$this->branch->id}")
            ->assertJsonPath('data.0.reason', 'count')
            ->assertJsonPath('data.0.change', -8.5)
            ->assertJsonPath('data.0.note', 'Monthly count');

        $this->postJson('/api/v1/inventory/counts', [
            'branch_id' => $this->branch->id,
            'inventory_item_id' => $this->shampoo->id,
            'quantity' => 1.5,
        ])->assertOk();
        $this->getJson("/api/v1/inventory/movements?branch_id={$this->branch->id}&inventory_item_id={$this->shampoo->id}")->assertJsonCount(2, 'data');
    }

    public function test_materials_are_managed_and_stock_stays_within_the_users_branches(): void
    {
        Sanctum::actingAs($this->keeper);
        $this->postJson('/api/v1/inventory/items', ['name' => 'Wax', 'unit' => 'kg', 'min_stock' => 0.5])
            ->assertCreated()
            ->assertJsonPath('data.min_stock', 0.5)
            ->assertJsonPath('data.quantity', 0);
        $this->postJson('/api/v1/inventory/items', ['name' => 'Wax', 'unit' => 'kg'])->assertUnprocessable()->assertJsonValidationErrors('name');

        $this->purchase(['branch_id' => $this->otherBranch->id])->assertForbidden();
        $this->getJson("/api/v1/inventory/items?branch_id={$this->otherBranch->id}")->assertForbidden();

        Sanctum::actingAs($this->cashier);
        $this->getJson('/api/v1/inventory/items')->assertForbidden();
        $this->purchase([])->assertCreated();
        Sanctum::actingAs($this->cashier);
        $this->postJson('/api/v1/inventory/counts', ['branch_id' => $this->branch->id, 'inventory_item_id' => $this->shampoo->id, 'quantity' => 1])->assertForbidden();
    }

    public function test_a_purchase_paid_from_the_drawer_needs_an_open_shift(): void
    {
        Sanctum::actingAs($this->owner);
        $this->postJson('/api/v1/inventory/purchases', [
            'branch_id' => $this->branch->id,
            'expense_category_id' => $this->supplies->id,
            'payment_method' => 'cash_drawer',
            'lines' => [['inventory_item_id' => $this->towels->id, 'quantity' => 10, 'unit_cost' => 50]],
        ])->assertUnprocessable()->assertJsonValidationErrors('payment_method');

        $this->assertSame(0, $this->inTenant(fn () => Purchase::query()->count()));
    }
}
