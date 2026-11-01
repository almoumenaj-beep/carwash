<?php

namespace App\Http\Resources;

use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Orders\Models\OrderItem;
use App\Domain\Orders\Models\OrderStatusChange;
use App\Domain\Sales\Models\Payment;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A work order for the queue and its detail screen. Amounts are in minor units (BHD: fils).
 * `allowed_next` lists the statuses the order may move to, for the action buttons; `delivered`
 * only appears once the order is paid (`invoice`).
 *
 * @mixin Order
 */
class OrderResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'number' => $this->number,
            'reference' => $this->reference(),
            'branch_id' => $this->branch_id,
            'status' => $this->status,
            'allowed_next' => array_map(fn (OrderStatus $status) => $status->value, $this->allowedNext()),
            'is_paid' => $this->isPaid(),
            'invoice' => $this->invoice === null ? null : [
                'id' => $this->invoice->id,
                'reference' => $this->invoice->reference(),
                'subtotal' => $this->invoice->subtotal,
                'discount_total' => $this->invoice->discount_total,
                'discount_reason' => $this->invoice->discount_reason,
                'total' => $this->invoice->total,
                'vat_rate_bps' => $this->invoice->vat_rate_bps,
                'vat_amount' => $this->invoice->vat_amount,
                'issued_at' => $this->invoice->issued_at->toIso8601String(),
                'payments' => $this->invoice->payments->map(fn (Payment $payment) => [
                    'method' => $payment->method,
                    'amount' => $payment->amount,
                    'tendered' => $payment->tendered,
                    'change_given' => $payment->change_given,
                ])->values(),
            ],
            'customer' => $this->customer === null ? null : [
                'id' => $this->customer->id,
                'name' => $this->customer->name,
                'phone' => $this->customer->phone,
            ],
            'vehicle_id' => $this->vehicle_id,
            'plate_number' => $this->plate_number,
            'vehicle_size_id' => $this->vehicle_size_id,
            'bay' => $this->bay === null ? null : ['id' => $this->bay->id, 'name' => $this->bay->name],
            'staff' => $this->staff->map(fn (User $user) => ['id' => $user->id, 'name' => $user->name])->values(),
            'items' => $this->items->map(fn (OrderItem $item) => [
                'id' => $item->id,
                'service_id' => $item->service_id,
                'name' => $item->name,
                'is_addon' => $item->is_addon,
                'quantity' => $item->quantity,
                'unit_price' => $item->unit_price,
                'line_total' => $item->line_total,
                'duration_minutes' => $item->duration_minutes,
            ])->values(),
            'subtotal' => $this->subtotal,
            'estimated_minutes' => $this->estimated_minutes,
            'notes' => $this->notes,
            'cancel_reason' => $this->cancel_reason,
            'created_by' => ['id' => $this->creator->id, 'name' => $this->creator->name],
            'created_at' => $this->created_at?->toIso8601String(),
            'started_at' => $this->started_at?->toIso8601String(),
            'qc_at' => $this->qc_at?->toIso8601String(),
            'ready_at' => $this->ready_at?->toIso8601String(),
            'delivered_at' => $this->delivered_at?->toIso8601String(),
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'history' => $this->whenLoaded('statusHistory', fn () => $this->statusHistory->map(fn (OrderStatusChange $change) => [
                'from' => $change->from_status?->value,
                'to' => $change->to_status->value,
                'by' => $change->user?->name,
                'reason' => $change->reason,
                'at' => $change->created_at?->toIso8601String(),
            ])->values()),
        ];
    }
}
