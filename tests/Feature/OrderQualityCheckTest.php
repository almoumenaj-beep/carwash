<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class OrderQualityCheckTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    private string $orderId;

    /** @var array{wash: string, freshener: string} */
    private array $itemIds;

    /**
     * A sedan in quality check after an exterior wash and an air freshener.
     */
    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
        $order = $this->checkIn(['items' => [['service_id' => $this->wash->id], ['service_id' => $this->freshener->id]]]);
        $this->orderId = $order->json('data.id');
        $this->itemIds = [
            'wash' => $order->json('data.items.0.id'),
            'freshener' => $order->json('data.items.1.id'),
        ];
        $this->moveTo($this->orderId, 'in_progress', $this->washer)->assertOk();
        $this->moveTo($this->orderId, 'qc', $this->washer)->assertOk();
    }

    /**
     * @return list<array{item_id: string, passed: bool}>
     */
    private function checklist(bool $washPassed, bool $freshenerPassed): array
    {
        return [
            ['item_id' => $this->itemIds['wash'], 'passed' => $washPassed],
            ['item_id' => $this->itemIds['freshener'], 'passed' => $freshenerPassed],
        ];
    }

    public function test_every_car_goes_through_the_quality_check_on_its_way_to_ready(): void
    {
        $orderId = $this->checkIn()->json('data.id');
        $this->moveTo($orderId, 'in_progress', $this->washer)->assertJsonPath('data.allowed_next', ['qc', 'waiting', 'cancelled']);

        $this->moveTo($orderId, 'ready', $this->washer)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['status' => 'An order cannot move from In progress to Ready.']);
    }

    public function test_a_car_passes_once_every_service_on_the_order_is_ticked(): void
    {
        $this->moveTo($this->orderId, 'ready', $this->washer)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['checklist' => 'Tick every service on the order to pass the car.']);
        $this->moveTo($this->orderId, 'ready', $this->washer, ['checklist' => $this->checklist(true, false)])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('checklist');

        $this->moveTo($this->orderId, 'ready', $this->washer, ['checklist' => $this->checklist(true, true)])
            ->assertOk()
            ->assertJsonPath('data.status', 'ready')
            ->assertJsonPath('data.quality_checks.0.passed', true)
            ->assertJsonPath('data.quality_checks.0.by', $this->washer->name)
            ->assertJsonPath('data.quality_checks.0.results.0.name', 'Exterior wash')
            ->assertJsonPath('data.quality_checks.0.results.1.passed', true);
    }

    public function test_a_car_sent_back_for_rework_records_which_services_were_not_done_properly(): void
    {
        $this->moveTo($this->orderId, 'in_progress', $this->washer, ['checklist' => $this->checklist(true, false)])
            ->assertOk()
            ->assertJsonPath('data.status', 'in_progress')
            ->assertJsonPath('data.quality_checks.0.passed', false)
            ->assertJsonPath('data.quality_checks.0.results.1.name', 'Air freshener')
            ->assertJsonPath('data.quality_checks.0.results.1.passed', false);

        $this->moveTo($this->orderId, 'qc', $this->washer)->assertOk();
        $this->moveTo($this->orderId, 'ready', $this->washer, ['checklist' => $this->checklist(true, true)])
            ->assertOk()
            ->assertJsonCount(2, 'data.quality_checks')
            ->assertJsonPath('data.quality_checks.1.passed', true);
    }

    public function test_ticks_for_services_of_another_order_do_not_count(): void
    {
        $other = $this->checkIn()->json('data.items.0.id');

        $this->moveTo($this->orderId, 'ready', $this->washer, ['checklist' => [
            ['item_id' => $other, 'passed' => true],
            ['item_id' => $this->itemIds['freshener'], 'passed' => true],
        ]])->assertUnprocessable()->assertJsonValidationErrors('checklist');
    }
}
