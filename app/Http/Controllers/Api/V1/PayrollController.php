<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Domain\Staff\Actions\CalculatePayroll;
use App\Domain\Staff\Actions\PayPayroll;
use App\Domain\Staff\Models\PayrollLine;
use App\Domain\Staff\Models\PayrollRun;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

/**
 * Monthly payroll: calculated (and recalculated) as a draft, then paid. Seen with payroll.view, calculated and
 * paid with payroll.run. Amounts in minor units.
 */
class PayrollController extends Controller
{
    public function index(): JsonResponse
    {
        Gate::authorize(Permission::PayrollView->value);

        $runs = PayrollRun::query()->with('lines.user')->orderByDesc('year')->orderByDesc('month')->limit(24)->get();

        return response()->json(['data' => $runs->map($this->present(...))]);
    }

    /**
     * Calculate a month: creates its draft, or recalculates the existing draft.
     */
    public function store(Request $request, CalculatePayroll $calculatePayroll): JsonResponse
    {
        Gate::authorize(Permission::PayrollRun->value);
        $validated = $request->validate([
            'year' => ['required', 'integer', 'between:2024,2100'],
            'month' => ['required', 'integer', 'between:1,12'],
        ]);

        $run = $calculatePayroll->handle($request->user(), $validated['year'], $validated['month']);

        return response()->json(['data' => $this->present($run->load('lines.user'))]);
    }

    /**
     * Pay a month's draft, recorded as an expense of a branch.
     */
    public function pay(Request $request, PayrollRun $payrollRun, PayPayroll $payPayroll): JsonResponse
    {
        Gate::authorize(Permission::PayrollRun->value);

        $tenantId = $request->user()->tenant_id;
        $validated = $request->validate([
            'branch_id' => ['required', 'uuid'],
            'expense_category_id' => ['required', 'uuid', Rule::exists('expense_categories', 'id')->where('tenant_id', $tenantId)],
            'payment_method' => ['required', Rule::enum(ExpensePaymentMethod::class)],
        ]);
        Gate::authorize('view', Branch::query()->findOrFail($validated['branch_id']));

        $run = $payPayroll->handle($request->user(), $payrollRun, $validated);

        return response()->json(['data' => $this->present($run->load('lines.user'))]);
    }

    /**
     * @return array<string, mixed>
     */
    private function present(PayrollRun $run): array
    {
        return [
            'id' => $run->id,
            'year' => $run->year,
            'month' => $run->month,
            'status' => $run->status,
            'total_net' => $run->total_net,
            'paid_at' => $run->paid_at?->toIso8601String(),
            'lines' => $run->lines->sortBy(fn (PayrollLine $line) => $line->user->name)->map(fn (PayrollLine $line) => [
                'user' => ['id' => $line->user->id, 'name' => $line->user->name],
                'base_salary' => $line->base_salary,
                'cars_count' => $line->cars_count,
                'commission' => $line->commission,
                'net' => $line->net,
            ])->values(),
        ];
    }
}
