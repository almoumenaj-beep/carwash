<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Domain\Reports\Queries\DailySales;
use App\Http\Controllers\Controller;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class DailySalesReportController extends Controller
{
    /**
     * One day's sales (`date`, default today in the car wash's time zone) at a branch, or at every
     * branch the user works in when `branch_id` is left out. Needs reports.sales.
     */
    public function __invoke(Request $request, DailySales $dailySales): JsonResponse
    {
        Gate::authorize(Permission::ReportsSales->value);

        $request->validate([
            'branch_id' => ['sometimes', 'nullable', 'uuid'],
            'date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
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
        $day = $request->filled('date')
            ? CarbonImmutable::createFromFormat('Y-m-d', $request->input('date'), $timezone)
            : CarbonImmutable::now($timezone);

        return response()->json(['data' => [
            'branch_id' => $request->input('branch_id'),
            ...$dailySales->for($branchIds, $day),
        ]]);
    }
}
