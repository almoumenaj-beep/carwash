<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Domain\Sales\Actions\CloseCashShift;
use App\Domain\Sales\Actions\OpenCashShift;
use App\Domain\Sales\Models\CashShift;
use App\Http\Controllers\Controller;
use App\Http\Requests\CloseCashShiftRequest;
use App\Http\Requests\OpenCashShiftRequest;
use App\Http\Resources\CashShiftResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Cashier shifts: open with a float, take cash on it, close with the drawer counted.
 */
class CashShiftController extends Controller
{
    /**
     * Recent shifts at a branch, newest first: everyone's for staff with reports.sales, otherwise
     * only the user's own.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['branch_id' => ['required', 'uuid']]);

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        $shifts = CashShift::query()
            ->where('branch_id', $branch->id)
            ->unless($request->user()->can(Permission::ReportsSales->value), fn ($query) => $query->where('opened_by', $request->user()->id))
            ->with(['branch', 'opener', 'closer'])
            ->latest('opened_at')
            ->limit(30)
            ->get();

        return CashShiftResource::collection($shifts);
    }

    /**
     * All of the user's open shifts, at every branch. Used to make sure they close their cashier
     * before clocking out or signing out.
     */
    public function mine(Request $request): AnonymousResourceCollection
    {
        $shifts = CashShift::query()
            ->open()
            ->where('opened_by', $request->user()->id)
            ->with(['branch', 'opener', 'closer'])
            ->get();

        return CashShiftResource::collection($shifts);
    }

    /**
     * The user's open shift at a branch, or `data: null` when they have none.
     */
    public function current(Request $request): JsonResponse
    {
        $request->validate(['branch_id' => ['required', 'uuid']]);

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        $shift = CashShift::openFor($request->user(), $branch);

        return response()->json(['data' => $shift === null ? null : CashShiftResource::make($shift->load(['branch', 'opener', 'closer']))]);
    }

    public function store(OpenCashShiftRequest $request, OpenCashShift $openCashShift): JsonResponse
    {
        $shift = $openCashShift->handle(
            $request->user(),
            Branch::query()->findOrFail($request->validated('branch_id')),
            $request->integer('opening_float'),
        );

        return CashShiftResource::make($shift->load(['branch', 'opener', 'closer']))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    /**
     * Close the shift with the drawer counted; the response is the shift's closing summary.
     */
    public function close(CloseCashShiftRequest $request, CashShift $shift, CloseCashShift $closeCashShift): CashShiftResource
    {
        $shift = $closeCashShift->handle($request->user(), $shift, $request->integer('counted_cash'), $request->validated('note'));

        return CashShiftResource::make($shift->load(['branch', 'opener', 'closer']));
    }
}
