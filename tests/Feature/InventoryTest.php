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

    /**
     * @param  list<array{0: InventoryItem, 1: int|float}>  $lines
     * @param  array<string, mixed>  $overrides
     */
    private function issue(array $lines, array $overrides = [], ?User $as = null): TestResponse
    {
        Sanctum::actingAs($as ?? $this->keeper);

        return $this->postJson('/api/v1/inventory/issues', [
            'branch_id' => $this->branch->id,
            'issued_to' => $this->washer->id,
            'lines' => array_map(fn (array $line) => ['inventory_item_id' => $line[0]->id, 'quantity' => $line[1]], $lines),
            ...$overrides,
        ]);
    }

    public function test_several_materials_are_issued_to_a_staff_member_and_show_in_the_days_usage(): void
    {
        $this->purchase()->assertCreated();

        $this->issue([[$this->shampoo, 1.5], [$this->towels, 20]], ['note' => 'Morning supply'])->assertCreated()->assertJsonCount(2, 'data');

        $this->assertSame(1, $this->inTenant(fn () => Expense::query()->count()), 'the purchase was the only expense');

        $this->getJson("/api/v1/inventory/items?branch_id={$this->branch->id}")
            ->assertJsonFragment(['name' => 'Shampoo', 'quantity' => 8.5])
            ->assertJsonFragment(['name' => 'Towels', 'quantity' => 80]);

        $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonCount(2, 'data.items')
            ->assertJsonPath('data.items.0.item.name', 'Shampoo')
            ->assertJsonPath('data.items.0.issued', 1.5)
            ->assertJsonPath('data.items.0.washes', 0)
            ->assertJsonPath('data.items.0.cost', 1875)
            ->assertJsonCount(2, 'data.issues')
            ->assertJsonPath('data.issues.0.note', 'Morning supply')
            ->assertJsonPath('data.issues.0.by', $this->keeper->name)
            ->assertJsonPath('data.issues.0.received_by', $this->washer->name);

        $this->getJson("/api/v1/inventory/movements?branch_id={$this->branch->id}&inventory_item_id={$this->towels->id}")
            ->assertJsonPath('data.0.reason', 'issue')
            ->assertJsonPath('data.0.received_by', $this->washer->name);

        $yesterday = now($this->tenant->timezone)->subDay()->toDateString();
        $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}&date={$yesterday}")
            ->assertOk()
            ->assertJsonPath('data.items', []);
    }

    public function test_an_issue_is_all_or_nothing_and_never_more_than_the_stock(): void
    {
        $this->purchase()->assertCreated();

        $this->issue([[$this->shampoo, 1], [$this->towels, 101]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('lines.1.quantity');

        $this->getJson("/api/v1/inventory/items?branch_id={$this->branch->id}")->assertJsonFragment(['name' => 'Shampoo', 'quantity' => 10]);
        $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}")->assertJsonPath('data.items', []);

        $this->issue([[$this->shampoo, 0]])->assertUnprocessable();
        $this->issue([])->assertUnprocessable()->assertJsonValidationErrors('lines');
        $this->issue([[$this->shampoo, 1], [$this->shampoo, 1]])->assertUnprocessable();
    }

    public function test_the_receiver_must_work_at_the_branch_and_issuing_needs_the_permission(): void
    {
        $this->purchase()->assertCreated();
        $elsewhere = $this->createStaff($this->tenant, DefaultRole::Washer, [$this->otherBranch]);

        $this->issue([[$this->shampoo, 1]], ['issued_to' => null])->assertUnprocessable()->assertJsonValidationErrors('issued_to');
        $this->issue([[$this->shampoo, 1]], ['issued_to' => $elsewhere->id])->assertUnprocessable()->assertJsonValidationErrors('issued_to');
        $this->issue([[$this->shampoo, 1]], ['branch_id' => $this->otherBranch->id])->assertForbidden();

        $this->issue([[$this->shampoo, 1]], as: $this->cashier)->assertForbidden();
        $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}")->assertForbidden();
    }

    public function test_cancelling_an_issue_puts_the_quantity_back_and_keeps_it_on_record(): void
    {
        $this->purchase()->assertCreated();
        $this->issue([[$this->shampoo, 1.5], [$this->towels, 20]])->assertCreated();

        $usage = $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}");
        $towelIssue = collect($usage->json('data.issues'))->firstWhere('item.name', 'Towels');

        $this->postJson("/api/v1/inventory/issues/{$towelIssue['id']}/cancel")
            ->assertOk()
            ->assertJsonPath('data.name', 'Towels')
            ->assertJsonPath('data.quantity', 100);

        $this->getJson("/api/v1/inventory/items?branch_id={$this->branch->id}")
            ->assertJsonFragment(['name' => 'Shampoo', 'quantity' => 8.5])
            ->assertJsonFragment(['name' => 'Towels', 'quantity' => 100]);

        $usage = $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}")
            ->assertJsonCount(1, 'data.items', 'a cancelled issue no longer counts as usage')
            ->assertJsonPath('data.items.0.item.name', 'Shampoo')
            ->assertJsonCount(2, 'data.issues');
        $cancelled = collect($usage->json('data.issues'))->firstWhere('item.name', 'Towels');
        $this->assertTrue($cancelled['is_cancelled']);
        $this->assertSame($this->keeper->name, $cancelled['cancelled_by']);

        $this->getJson("/api/v1/inventory/movements?branch_id={$this->branch->id}&inventory_item_id={$this->towels->id}")
            ->assertJsonPath('data.0.reason', 'reversal')
            ->assertJsonPath('data.0.change', 20)
            ->assertJsonPath('data.1.reason', 'issue');
        $this->assertDatabaseHas('activity_log', ['event' => 'stock.issue_cancelled', 'tenant_id' => $this->tenant->id]);
    }

    public function test_an_issue_is_cancelled_once_and_only_issues_can_be_cancelled(): void
    {
        $this->purchase()->assertCreated();
        $this->issue([[$this->shampoo, 1]])->assertCreated();
        $issueId = $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}")->json('data.issues.0.id');

        $this->postJson("/api/v1/inventory/issues/{$issueId}/cancel")->assertOk();
        $this->postJson("/api/v1/inventory/issues/{$issueId}/cancel")->assertUnprocessable()->assertJsonValidationErrors('movement');
        $this->getJson("/api/v1/inventory/items?branch_id={$this->branch->id}")->assertJsonFragment(['name' => 'Shampoo', 'quantity' => 10]);

        $purchaseMovement = $this->getJson("/api/v1/inventory/movements?branch_id={$this->branch->id}&inventory_item_id={$this->towels->id}")->json('data.0.id');
        $this->postJson("/api/v1/inventory/issues/{$purchaseMovement}/cancel")->assertUnprocessable()->assertJsonValidationErrors('movement');
    }

    public function test_cancelling_needs_the_permission_and_the_branch(): void
    {
        $this->purchase()->assertCreated();
        $this->issue([[$this->shampoo, 1]])->assertCreated();
        $issueId = $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}")->json('data.issues.0.id');

        Sanctum::actingAs($this->cashier);
        $this->postJson("/api/v1/inventory/issues/{$issueId}/cancel")->assertForbidden();

        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::InventoryKeeper, [$this->otherBranch]));
        $this->postJson("/api/v1/inventory/issues/{$issueId}/cancel")->assertForbidden();

        Sanctum::actingAs($this->keeper);
        $this->getJson("/api/v1/inventory/items?branch_id={$this->branch->id}")->assertJsonFragment(['name' => 'Shampoo', 'quantity' => 9]);
    }

    public function test_a_purchase_expense_is_managed_from_the_inventory_not_deleted_from_the_expenses(): void
    {
        $this->purchase(['payment_method' => 'cash'])->assertCreated();
        $expense = $this->inTenant(fn () => Expense::query()->sole());

        Sanctum::actingAs($this->owner);
        $this->getJson('/api/v1/expenses')->assertJsonPath('data.0.source', 'purchase');
        $this->deleteJson("/api/v1/expenses/{$expense->id}")->assertUnprocessable()->assertJsonValidationErrors('expense');

        $this->assertSame(1, $this->inTenant(fn () => Expense::query()->count()));
    }

    public function test_cancelling_a_purchase_takes_the_stock_and_expense_back_and_keeps_it_listed(): void
    {
        $purchaseId = $this->purchase()->json('data.id');
        Sanctum::actingAs($this->keeper);

        $this->postJson("/api/v1/inventory/purchases/{$purchaseId}/cancel")
            ->assertOk()
            ->assertJsonPath('data.is_cancelled', true)
            ->assertJsonPath('data.cancelled_by', $this->keeper->name);

        $stock = $this->stockByName($this->branch->id);
        $this->assertEquals(0, $stock['Shampoo']['quantity']);
        $this->assertEquals(0, $stock['Towels']['quantity']);
        $this->assertSame(0, $this->inTenant(fn () => Expense::query()->count()));

        $this->getJson("/api/v1/inventory/purchases?branch_id={$this->branch->id}")->assertJsonPath('data.0.is_cancelled', true);
        $this->getJson("/api/v1/inventory/movements?branch_id={$this->branch->id}&inventory_item_id={$this->shampoo->id}")
            ->assertJsonPath('data.0.reason', 'cancellation')
            ->assertJsonPath('data.0.change', -10);
        $this->assertDatabaseHas('activity_log', ['event' => 'purchase.cancelled', 'tenant_id' => $this->tenant->id]);

        $this->postJson("/api/v1/inventory/purchases/{$purchaseId}/cancel")->assertUnprocessable()->assertJsonValidationErrors('purchase');
    }

    public function test_a_purchase_partly_used_cannot_be_cancelled_and_nothing_changes(): void
    {
        $purchaseId = $this->purchase()->json('data.id');
        $this->issue([[$this->towels, 1]])->assertCreated();

        $this->postJson("/api/v1/inventory/purchases/{$purchaseId}/cancel")->assertUnprocessable()->assertJsonValidationErrors('purchase');

        $stock = $this->stockByName($this->branch->id);
        $this->assertEquals(10, $stock['Shampoo']['quantity']);
        $this->assertEquals(99, $stock['Towels']['quantity']);
        $this->assertSame(1, $this->inTenant(fn () => Expense::query()->count()));
    }

    public function test_cancelling_a_purchase_returns_the_cost_to_the_last_one_standing(): void
    {
        $this->purchase()->assertCreated();
        $mistakeId = $this->purchase(['lines' => [['inventory_item_id' => $this->shampoo->id, 'quantity' => 1, 'unit_cost' => 9000]]])->json('data.id');
        $this->assertSame(9000, $this->stockByName($this->branch->id)['Shampoo']['unit_cost']);

        $this->postJson("/api/v1/inventory/purchases/{$mistakeId}/cancel")->assertOk();

        $this->assertSame(1250, $this->stockByName($this->branch->id)['Shampoo']['unit_cost']);
    }

    public function test_cancelling_a_paid_purchase_also_needs_the_right_to_approve_expenses(): void
    {
        $purchaseId = $this->purchase(['payment_method' => 'cash'])->json('data.id');

        Sanctum::actingAs($this->keeper);
        $this->postJson("/api/v1/inventory/purchases/{$purchaseId}/cancel")->assertForbidden();
        $this->assertSame(1, $this->inTenant(fn () => Expense::query()->count()));

        Sanctum::actingAs($this->owner);
        $this->postJson("/api/v1/inventory/purchases/{$purchaseId}/cancel")->assertOk();
        $this->assertSame(0, $this->inTenant(fn () => Expense::query()->count()));
    }

    public function test_the_inventory_keeper_can_prepare_a_purchase_without_seeing_what_is_owed(): void
    {
        $this->purchase()->assertCreated();
        Sanctum::actingAs($this->keeper);

        $this->getJson('/api/v1/expense-categories')->assertOk();
        $this->getJson('/api/v1/suppliers')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Gulf Chemicals')
            ->assertJsonPath('data.0.owed', 0);
        $this->postJson('/api/v1/suppliers', ['name' => 'New supplier'])->assertCreated();
        $this->patchJson("/api/v1/suppliers/{$this->supplier->id}", ['name' => 'Renamed'])->assertForbidden();
        $this->getJson('/api/v1/expenses')->assertForbidden();

        Sanctum::actingAs($this->cashier);
        $this->getJson('/api/v1/suppliers')->assertForbidden();
        $this->getJson('/api/v1/expense-categories')->assertForbidden();

        Sanctum::actingAs($this->owner);
        $owed = collect($this->getJson('/api/v1/suppliers')->json('data'))->firstWhere('name', 'Gulf Chemicals');
        $this->assertSame(17500, $owed['owed']);
    }

    public function test_materials_set_on_a_service_still_show_in_the_days_usage(): void
    {
        $this->purchase()->assertCreated();
        $this->inTenant(fn () => $this->wash->materials()->attach($this->shampoo->id, ['quantity_milli' => 250]));

        $this->moveTo($this->checkIn()->json('data.id'), 'in_progress', $this->washer)->assertOk();

        Sanctum::actingAs($this->keeper);
        $this->postJson('/api/v1/inventory/counts', ['branch_id' => $this->branch->id, 'inventory_item_id' => $this->towels->id, 'quantity' => 90])->assertSuccessful();

        $this->getJson("/api/v1/inventory/daily-usage?branch_id={$this->branch->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.washes', 0.25)
            ->assertJsonPath('data.issues', []);
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
