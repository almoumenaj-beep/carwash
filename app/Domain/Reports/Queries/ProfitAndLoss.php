<?php

namespace App\Domain\Reports\Queries;

use App\Domain\Catalog\Models\Service;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseCategory;
use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Platform\Models\Branch;
use App\Domain\Sales\Models\Invoice;
use App\Domain\Sales\Models\InvoiceLine;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

/**
 * Profit and loss for a period at one or more branches, with what each branch, service and washer brought in.
 *
 * Sales are the invoices issued in the period; `net_sales` leaves out VAT. Expenses are those dated in the
 * period, paid or owed (materials count when bought, wages when payroll is paid), so `profit` is net sales
 * less expenses. Per service, revenue is shared out of each invoice after its discount and VAT, and
 * `materials` estimates what the service uses at today's material costs. Per washer, each car's net value is
 * split between the staff who washed it, and `pay` is their salary and commission in the period's payrolls.
 * The period runs from the start of `$from` to the end of `$to` in the car wash's time zone.
 * Amounts are in minor units (BHD: fils).
 */
class ProfitAndLoss
{
    /**
     * @param  list<string>  $branchIds
     * @return array<string, mixed>
     */
    public function for(array $branchIds, CarbonImmutable $from, CarbonImmutable $to): array
    {
        $start = $from->startOfDay()->utc();
        $end = $to->startOfDay()->addDay()->utc();
        $invoices = fn () => Invoice::query()->whereIn('invoices.branch_id', $branchIds)->where('invoices.issued_at', '>=', $start)->where('invoices.issued_at', '<', $end);
        $expenses = fn () => Expense::query()->whereIn('expenses.branch_id', $branchIds)->whereBetween('spent_on', [$from->toDateString(), $to->toDateString()]);

        $sales = (int) $invoices()->sum('total');
        $vat = (int) $invoices()->sum('vat_amount');
        $netSales = $sales - $vat;
        $byCategory = $this->byCategory($expenses());
        $totalExpenses = array_sum(array_column($byCategory, 'amount'));
        $profit = $netSales - $totalExpenses;

        return [
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
            'revenue' => [
                'invoices_count' => $invoices()->count(),
                'gross' => (int) $invoices()->sum('subtotal'),
                'discounts' => (int) $invoices()->sum('discount_total'),
                'sales' => $sales,
                'vat' => $vat,
                'net_sales' => $netSales,
            ],
            'expenses' => [
                'total' => $totalExpenses,
                'owed' => (int) $expenses()->whereNull('paid_at')->sum('amount'),
                'by_category' => $byCategory,
            ],
            'profit' => $profit,
            'margin_bps' => $netSales === 0 ? null : intdiv($profit * 10000, $netSales),
            'by_branch' => $this->byBranch($branchIds, $invoices(), $expenses()),
            'by_service' => $this->byService($invoices()),
            'by_washer' => $this->byWasher($invoices(), $from, $to),
        ];
    }

    /**
     * @param  Builder<Expense>  $expenses
     * @return list<array{id: string, name: string, amount: int}>
     */
    private function byCategory($expenses): array
    {
        $amounts = $expenses->groupBy('expense_category_id')->selectRaw('expense_category_id, SUM(amount) AS amount')->pluck('amount', 'expense_category_id');
        $names = ExpenseCategory::query()->whereKey($amounts->keys())->pluck('name', 'id');

        return $amounts
            ->map(fn ($amount, string $id) => ['id' => $id, 'name' => $names[$id] ?? '—', 'amount' => (int) $amount])
            ->sortByDesc('amount')
            ->values()
            ->all();
    }

    /**
     * @param  list<string>  $branchIds
     * @param  Builder<Invoice>  $invoices
     * @param  Builder<Expense>  $expenses
     * @return list<array{id: string, name: string, net_sales: int, expenses: int, profit: int}>
     */
    private function byBranch(array $branchIds, $invoices, $expenses): array
    {
        $sales = $invoices->groupBy('invoices.branch_id')->selectRaw('invoices.branch_id, SUM(total - vat_amount) AS net_sales')->pluck('net_sales', 'branch_id');
        $spent = $expenses->groupBy('expenses.branch_id')->selectRaw('expenses.branch_id, SUM(amount) AS amount')->pluck('amount', 'branch_id');

        return Branch::query()->whereKey($branchIds)->orderBy('name')->get()
            ->map(fn (Branch $branch) => [
                'id' => $branch->id,
                'name' => $branch->name,
                'net_sales' => (int) ($sales[$branch->id] ?? 0),
                'expenses' => (int) ($spent[$branch->id] ?? 0),
                'profit' => (int) ($sales[$branch->id] ?? 0) - (int) ($spent[$branch->id] ?? 0),
            ])
            ->sortByDesc('profit')
            ->values()
            ->all();
    }

    /**
     * Each service sold: how many, its share of net sales, and the materials it is estimated to use.
     *
     * @param  Builder<Invoice>  $invoices
     * @return list<array{service_id: ?string, name: string, quantity: int, net_revenue: int, materials: int, profit: int}>
     */
    private function byService($invoices): array
    {
        $rows = InvoiceLine::query()
            ->joinSub($invoices->select(['invoices.id', 'invoices.subtotal', 'invoices.total', 'invoices.vat_amount']), 'sold', 'sold.id', '=', 'invoice_lines.invoice_id')
            ->groupBy('invoice_lines.service_id', 'invoice_lines.name')
            ->selectRaw('invoice_lines.service_id, invoice_lines.name, SUM(invoice_lines.quantity) AS quantity,
                SUM(ROUND(invoice_lines.line_total * (sold.total - sold.vat_amount) / NULLIF(sold.subtotal, 0))) AS net_revenue')
            ->toBase()
            ->get();
        $materialCosts = $this->materialCosts();

        return $rows
            ->map(function ($row) use ($materialCosts): array {
                $materials = (int) $row->quantity * ($materialCosts[$row->service_id] ?? 0);

                return [
                    'service_id' => $row->service_id,
                    'name' => $row->name,
                    'quantity' => (int) $row->quantity,
                    'net_revenue' => (int) $row->net_revenue,
                    'materials' => $materials,
                    'profit' => (int) $row->net_revenue - $materials,
                ];
            })
            ->sortByDesc('net_revenue')
            ->values()
            ->all();
    }

    /**
     * What one of each service uses in materials at today's material costs, a package counted through its services.
     *
     * @return array<string, int>
     */
    private function materialCosts(): array
    {
        $own = DB::table('service_materials')
            ->join('inventory_items', 'inventory_items.id', '=', 'service_materials.inventory_item_id')
            ->whereIn('service_materials.service_id', Service::query()->select('id'))
            ->groupBy('service_materials.service_id')
            ->selectRaw('service_materials.service_id, ROUND(SUM(service_materials.quantity_milli * inventory_items.unit_cost) / 1000) AS cost')
            ->pluck('cost', 'service_id')
            ->map(fn ($cost) => (int) $cost)
            ->all();

        $costs = $own;
        $packages = Service::query()->where('is_package', true)->with('packageItems')->get();
        foreach ($packages as $package) {
            $costs[$package->id] = $package->packageItems->sum(fn (Service $service) => $own[$service->id] ?? 0);
        }

        return $costs;
    }

    /**
     * Cars each washer worked on in the period, their share of those cars' net value, and their pay.
     *
     * @param  Builder<Invoice>  $invoices
     * @return list<array{id: string, name: string, cars: int, net_revenue: int, pay: int}>
     */
    private function byWasher($invoices, CarbonImmutable $from, CarbonImmutable $to): array
    {
        $cars = $invoices
            ->join('orders', 'orders.id', '=', 'invoices.order_id')
            ->where('orders.status', '!=', OrderStatus::Cancelled)
            ->get(['invoices.order_id', 'invoices.total', 'invoices.vat_amount']);
        $washers = DB::table('order_staff')->whereIn('order_id', $cars->pluck('order_id'))->get(['order_id', 'user_id'])->groupBy('order_id');

        $totals = [];
        foreach ($cars as $car) {
            $staff = $washers[$car->order_id] ?? collect();
            foreach ($staff as $washer) {
                $totals[$washer->user_id] ??= ['cars' => 0, 'net_revenue' => 0];
                $totals[$washer->user_id]['cars']++;
                $totals[$washer->user_id]['net_revenue'] += intdiv(2 * ($car->total - $car->vat_amount) + $staff->count(), 2 * $staff->count());
            }
        }

        $pay = DB::table('payroll_lines')
            ->join('payroll_runs', 'payroll_runs.id', '=', 'payroll_lines.payroll_run_id')
            ->whereIn('payroll_lines.user_id', array_keys($totals))
            ->whereRaw('payroll_runs.year * 100 + payroll_runs.month BETWEEN ? AND ?', [$from->year * 100 + $from->month, $to->year * 100 + $to->month])
            ->groupBy('payroll_lines.user_id')
            ->selectRaw('payroll_lines.user_id, SUM(payroll_lines.base_salary + payroll_lines.commission) AS pay')
            ->pluck('pay', 'user_id');
        $names = User::query()->whereKey(array_keys($totals))->pluck('name', 'id');

        return collect($totals)
            ->map(fn (array $total, string $id) => ['id' => $id, 'name' => $names[$id] ?? '—', ...$total, 'pay' => (int) ($pay[$id] ?? 0)])
            ->sortByDesc('net_revenue')
            ->values()
            ->all();
    }
}
