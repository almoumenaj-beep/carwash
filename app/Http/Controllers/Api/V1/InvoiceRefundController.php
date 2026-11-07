<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Sales\Actions\RefundInvoice;
use App\Domain\Sales\Models\Invoice;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class InvoiceRefundController extends Controller
{
    /**
     * Give back a whole invoice, with the reason. Needs orders.refund, at a branch the user works in.
     */
    public function store(Request $request, Invoice $invoice, RefundInvoice $refundInvoice): JsonResponse
    {
        Gate::authorize(Permission::OrdersRefund->value);
        Gate::authorize('view', $invoice->branch);
        $request->validate(['reason' => ['required', 'string', 'max:255']]);

        $invoice = $refundInvoice->handle($request->user(), $invoice, $request->input('reason'));

        return response()->json(['data' => [
            'id' => $invoice->id,
            'reference' => $invoice->reference(),
            'refunded_at' => $invoice->refunded_at->toIso8601String(),
        ]]);
    }
}
