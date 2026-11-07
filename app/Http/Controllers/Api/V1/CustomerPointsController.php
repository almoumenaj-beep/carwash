<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Crm\Models\Customer;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Sales\Models\PointTransaction;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class CustomerPointsController extends Controller
{
    /**
     * The customer's points balance and latest movements, newest first.
     */
    public function show(Customer $customer): JsonResponse
    {
        Gate::authorize(Permission::CustomersView->value);

        $transactions = $customer->pointTransactions()
            ->with(['branch', 'creator', 'invoice.branch'])
            ->latest()
            ->orderByDesc('id')
            ->limit(50)
            ->get();

        return response()->json([
            'balance' => $customer->points_balance,
            'data' => $transactions->map(fn (PointTransaction $transaction) => [
                'id' => $transaction->id,
                'type' => $transaction->type,
                'points' => $transaction->points,
                'balance_after' => $transaction->balance_after,
                'branch_name' => $transaction->branch?->name,
                'invoice_reference' => $transaction->invoice?->reference(),
                'created_by' => $transaction->creator?->name,
                'created_at' => $transaction->created_at->toIso8601String(),
            ])->values(),
        ]);
    }
}
