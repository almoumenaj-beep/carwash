<?php

namespace App\Domain\Reports\Queries;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Sales\Models\Payment;
use App\Domain\Sales\Models\Refund;
use Carbon\CarbonImmutable;
use Carbon\CarbonPeriod;
use Illuminate\Support\Collection;

/**
 * Money that came in and went out over a period at one or more branches: payments received from
 * customers in, expenses actually paid out (by when they were paid, not when they were incurred). `owed`
 * is what the branches still owe today, whatever the period. The period runs from the start of `$from`
 * to the end of `$to` in the car wash's time zone. Amounts are in minor units (BHD: fils).
 */
class CashFlow
{
    /**
     * @param  list<string>  $branchIds
     * @return array<string, mixed>
     */
    public function for(array $branchIds, CarbonImmutable $from, CarbonImmutable $to): array
    {
        $start = $from->startOfDay()->utc();
        $end = $to->startOfDay()->addDay()->utc();
        $payments = Payment::query()->whereIn('branch_id', $branchIds)->where('received_at', '>=', $start)->where('received_at', '<', $end)->get(['method', 'amount', 'received_at']);
        $paidOut = Expense::query()->whereIn('branch_id', $branchIds)->where('paid_at', '>=', $start)->where('paid_at', '<', $end)->get(['payment_method', 'amount', 'paid_at']);
        $refunds = Refund::query()->whereIn('branch_id', $branchIds)->where('created_at', '>=', $start)->where('created_at', '<', $end)->get(['amount', 'created_at']);
        $owed = Expense::query()->whereIn('branch_id', $branchIds)->whereNull('paid_at');

        $inflow = (int) $payments->sum('amount');
        $refunded = (int) $refunds->sum('amount');
        $outflow = (int) $paidOut->sum('amount') + $refunded;

        return [
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
            'inflow' => [
                'total' => $inflow,
                'by_method' => $this->byMethod($payments, fn (Payment $payment) => $payment->method->value),
            ],
            'outflow' => [
                'total' => $outflow,
                'by_method' => [
                    ...$this->byMethod($paidOut, fn (Expense $expense) => $expense->payment_method->value),
                    ...($refunded > 0 ? [['method' => 'refund', 'amount' => $refunded]] : []),
                ],
            ],
            'net' => $inflow - $outflow,
            'owed' => ['total' => (int) $owed->sum('amount'), 'count' => $owed->count()],
            'by_day' => $this->byDay($payments, $paidOut, $refunds, $from, $to),
        ];
    }

    /**
     * @template TModel of \Illuminate\Database\Eloquent\Model
     *
     * @param  Collection<int, TModel>  $rows
     * @param  callable(TModel): string  $method
     * @return list<array{method: string, amount: int}>
     */
    private function byMethod($rows, callable $method): array
    {
        return $rows->groupBy($method)
            ->map(fn ($group, string $key) => ['method' => $key, 'amount' => (int) $group->sum('amount')])
            ->sortByDesc('amount')
            ->values()
            ->all();
    }

    /**
     * Money in and out on each day of the period (local dates), days without either left out.
     *
     * @param  Collection<int, Payment>  $payments
     * @param  Collection<int, Expense>  $paidOut
     * @param  Collection<int, Refund>  $refunds
     * @return list<array{date: string, inflow: int, outflow: int}>
     */
    private function byDay($payments, $paidOut, $refunds, CarbonImmutable $from, CarbonImmutable $to): array
    {
        $timezone = $from->getTimezone();
        $inflow = $payments->groupBy(fn (Payment $payment) => $payment->received_at->setTimezone($timezone)->toDateString())->map->sum('amount');
        $outflow = $paidOut->groupBy(fn (Expense $expense) => $expense->paid_at->setTimezone($timezone)->toDateString())->map->sum('amount');
        foreach ($refunds->groupBy(fn (Refund $refund) => $refund->created_at->setTimezone($timezone)->toDateString())->map->sum('amount') as $date => $amount) {
            $outflow[$date] = ($outflow[$date] ?? 0) + $amount;
        }

        $days = [];
        foreach (CarbonPeriod::create($from->toDateString(), $to->toDateString()) as $day) {
            $date = $day->toDateString();
            if (isset($inflow[$date]) || isset($outflow[$date])) {
                $days[] = ['date' => $date, 'inflow' => (int) ($inflow[$date] ?? 0), 'outflow' => (int) ($outflow[$date] ?? 0)];
            }
        }

        return $days;
    }
}
