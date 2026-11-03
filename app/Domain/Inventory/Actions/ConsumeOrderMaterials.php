<?php

namespace App\Domain\Inventory\Actions;

use App\Domain\Inventory\Enums\StockMovementReason;
use App\Domain\Inventory\Support\StockLedger;
use App\Domain\Orders\Models\Order;
use App\Domain\Orders\Models\OrderItem;

/**
 * Takes the materials a car's services use out of the branch's stock when its wash starts: each service's
 * bill of materials times its quantity, with a package counted through the services it includes.
 * Call once per order, inside the transaction that starts the wash.
 */
class ConsumeOrderMaterials
{
    public function __construct(private StockLedger $ledger) {}

    public function handle(Order $order, ?string $userId): void
    {
        $order->loadMissing('items.service.materials');
        $needs = [];

        foreach ($order->items->where('is_package', false) as $item) {
            /** @var OrderItem $item */
            foreach ($item->service?->materials ?? [] as $material) {
                $needs[$material->id] = ($needs[$material->id] ?? 0) + $material->pivot->quantity_milli * $item->quantity;
            }
        }

        foreach ($needs as $itemId => $milli) {
            $this->ledger->move($order->branch_id, $itemId, -$milli, StockMovementReason::Consumption, $userId, ['order_id' => $order->id]);
        }
    }
}
