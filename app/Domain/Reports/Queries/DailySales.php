<?php

namespace App\Domain\Reports\Queries;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Sales\Enums\PaymentMethod;
use App\Domain\Sales\Models\Invoice;
use App\Domain\Sales\Models\InvoiceLine;
use App\Domain\Sales\Models\Payment;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Builder;

/**
 * One day's sales at one or more branches: the day runs midnight to midnight in the car wash's time
 * zone. Sales come from the invoices issued that day, cars from the orders checked in that day, and
 * expenses from those dated that day (paid or owed); `net` is sales less expenses.
 * Amounts are in minor units (BHD: fils).
 */
class DailySales
{
    /**
     * @param  list<string>  $branchIds
     * @return array<string, mixed>
     */
    public function for(array $branchIds, CarbonImmutable $day): array
    {
        $from = $day->startOfDay()->utc();
        $to = $day->startOfDay()->addDay()->utc();
        $invoices = fn () => Invoice::query()->whereIn('invoices.branch_id', $branchIds)->where('issued_at', '>=', $from)->where('issued_at', '<', $to);
        $orders = fn () => Order::query()->whereIn('orders.branch_id', $branchIds)->where('orders.created_at', '>=', $from)->where('orders.created_at', '<', $to);

        $count = $invoices()->count();
        $sales = (int) $invoices()->sum('total');
        $expenses = (int) Expense::query()->whereIn('branch_id', $branchIds)->whereDate('spent_on', $day->toDateString())->sum('amount');
        $collected = fn (PaymentMethod $method): int => (int) Payment::query()
            ->whereIn('branch_id', $branchIds)
            ->where('method', $method->value)
            ->where('received_at', '>=', $from)
            ->where('received_at', '<', $to)
            ->sum('amount');

        return [
            'date' => $day->toDateString(),
            'totals' => [
                'invoices_count' => $count,
                'gross' => (int) $invoices()->sum('subtotal'),
                'discounts' => (int) $invoices()->sum('discount_total'),
                'sales' => $sales,
                'vat' => (int) $invoices()->sum('vat_amount'),
                'cash_collected' => $collected(PaymentMethod::Cash),
                'card_collected' => $collected(PaymentMethod::Card),
                'benefit_collected' => $collected(PaymentMethod::Benefit),
                'average_ticket' => $count === 0 ? 0 : intdiv($sales, $count),
                'expenses' => $expenses,
                'net' => $sales - $expenses,
            ],
            'cars' => [
                'checked_in' => $orders()->count(),
                'delivered' => $orders()->where('status', OrderStatus::Delivered)->count(),
                'cancelled' => $orders()->where('status', OrderStatus::Cancelled)->count(),
                'in_queue' => $orders()->whereIn('status', OrderStatus::activeValues())->count(),
            ],
            'by_service' => InvoiceLine::query()
                ->join('invoices', 'invoices.id', '=', 'invoice_lines.invoice_id')
                ->whereIn('invoices.branch_id', $branchIds)
                ->where('invoices.issued_at', '>=', $from)
                ->where('invoices.issued_at', '<', $to)
                ->groupBy('invoice_lines.name')
                ->selectRaw('invoice_lines.name, SUM(invoice_lines.quantity) AS quantity, SUM(invoice_lines.line_total) AS revenue')
                ->orderByDesc('revenue')
                ->get()
                ->map(fn ($row) => ['name' => $row->name, 'quantity' => (int) $row->quantity, 'revenue' => (int) $row->revenue])
                ->all(),
            'by_cashier' => $this->namedTotals(
                $invoices()->groupBy('issued_by')->selectRaw('issued_by AS user_id, COUNT(*) AS invoices, SUM(total) AS total'),
                fn ($row) => ['invoices' => (int) $row->invoices, 'total' => (int) $row->total],
            ),
            'by_washer' => $this->namedTotals(
                $orders()
                    ->join('order_staff', 'order_staff.order_id', '=', 'orders.id')
                    ->where('orders.status', '!=', OrderStatus::Cancelled)
                    ->groupBy('order_staff.user_id')
                    ->selectRaw('order_staff.user_id AS user_id, COUNT(*) AS cars'),
                fn ($row) => ['cars' => (int) $row->cars],
            ),
            'by_hour' => $this->byHour($invoices()->get(['issued_at', 'total']), $day),
        ];
    }

    /**
     * Rows grouped by user, with the user's name, biggest first.
     *
     * @param  Builder<covariant \Illuminate\Database\Eloquent\Model>  $query
     * @param  callable(object): array<string, int>  $values
     * @return list<array<string, mixed>>
     */
    private function namedTotals(Builder $query, callable $values): array
    {
        $rows = $query->toBase()->get();
        $names = User::query()->whereKey($rows->pluck('user_id'))->pluck('name', 'id');

        return $rows
            ->map(fn ($row) => ['id' => $row->user_id, 'name' => $names[$row->user_id] ?? '—', ...$values($row)])
            ->sortByDesc(fn (array $row) => $row['total'] ?? $row['cars'])
            ->values()
            ->all();
    }

    /**
     * Invoices and sales per hour of the day (local time), for the hours that had sales.
     *
     * @param  iterable<Invoice>  $invoices
     * @return list<array{hour: int, invoices: int, total: int}>
     */
    private function byHour(iterable $invoices, CarbonImmutable $day): array
    {
        $hours = [];

        foreach ($invoices as $invoice) {
            $hour = $invoice->issued_at->setTimezone($day->getTimezone())->hour;
            $hours[$hour] ??= ['hour' => $hour, 'invoices' => 0, 'total' => 0];
            $hours[$hour]['invoices']++;
            $hours[$hour]['total'] += $invoice->total;
        }

        ksort($hours);

        return array_values($hours);
    }
}
