<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Domain\Reports\Queries\CashFlow;
use App\Domain\Reports\Queries\ProfitAndLoss;
use App\Http\Controllers\Controller;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

/**
 * Profit and loss, and cash flow, over a period (`from`–`to`, default this month so far, at most a year)
 * at a branch, or at every branch the user works in when `branch_id` is left out. Needs reports.profit.
 */
class FinancialReportController extends Controller
{
    public function profitAndLoss(Request $request, ProfitAndLoss $profitAndLoss): JsonResponse
    {
        [$branchIds, $from, $to] = $this->scope($request);

        return response()->json(['data' => ['branch_id' => $request->input('branch_id'), ...$profitAndLoss->for($branchIds, $from, $to)]]);
    }

    public function cashFlow(Request $request, CashFlow $cashFlow): JsonResponse
    {
        [$branchIds, $from, $to] = $this->scope($request);

        return response()->json(['data' => ['branch_id' => $request->input('branch_id'), ...$cashFlow->for($branchIds, $from, $to)]]);
    }

    /**
     * The branches and the period asked for.
     *
     * @return array{0: list<string>, 1: CarbonImmutable, 2: CarbonImmutable}
     *
     * @throws ValidationException
     */
    private function scope(Request $request): array
    {
        Gate::authorize(Permission::ReportsProfit->value);

        $request->validate([
            'branch_id' => ['sometimes', 'nullable', 'uuid'],
            'from' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'to' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'after_or_equal:from'],
        ]);

        $user = $request->user();
        if ($request->filled('branch_id')) {
            $branch = Branch::query()->findOrFail($request->input('branch_id'));
            Gate::authorize('view', $branch);
            $branchIds = [$branch->id];
        } else {
            $branchIds = $user->accessibleBranches()->modelKeys();
        }

        $timezone = $user->tenant->timezone;
        $today = CarbonImmutable::now($timezone)->startOfDay();
        $from = $request->filled('from') ? CarbonImmutable::createFromFormat('Y-m-d', $request->input('from'), $timezone)->startOfDay() : $today->startOfMonth();
        $to = $request->filled('to') ? CarbonImmutable::createFromFormat('Y-m-d', $request->input('to'), $timezone)->startOfDay() : $today;

        if ($from->addYear()->lte($to)) {
            throw ValidationException::withMessages(['to' => __('The report covers a year at most.')]);
        }

        return [$branchIds, $from, $to];
    }
}
