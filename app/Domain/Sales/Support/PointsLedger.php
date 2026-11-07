<?php

namespace App\Domain\Sales\Support;

use App\Domain\Crm\Models\Customer;
use App\Domain\Sales\Enums\PointTransactionType;
use App\Domain\Sales\Models\PointTransaction;
use App\Models\User;

/**
 * The only way a customer's points move. The caller holds a lock on the customer inside a transaction, so two
 * counters can never spend the same points.
 */
class PointsLedger
{
    /**
     * @param  int  $points  Signed: positive adds points.
     */
    public function move(Customer $customer, PointTransactionType $type, int $points, ?string $branchId = null, ?User $actor = null, ?string $invoiceId = null): PointTransaction
    {
        $balance = $customer->points_balance + $points;
        $customer->forceFill(['points_balance' => $balance])->save();

        $transaction = new PointTransaction;
        $transaction->forceFill([
            'customer_id' => $customer->id,
            'branch_id' => $branchId,
            'type' => $type,
            'points' => $points,
            'balance_after' => $balance,
            'invoice_id' => $invoiceId,
            'created_by' => $actor?->id,
        ])->save();

        return $transaction;
    }
}
