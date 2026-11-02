<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Expenses\Actions\DeleteExpense;
use App\Domain\Expenses\Actions\PayExpense;
use App\Domain\Expenses\Actions\RecordExpense;
use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreExpenseRequest;
use App\Http\Resources\ExpenseResource;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

/**
 * Money spent by the branches: recorded paid or owed, paid later, deleted when recorded by mistake.
 */
class ExpenseController extends Controller
{
    private const RELATIONS = ['category', 'supplier', 'creator'];

    /**
     * Expenses of a branch (or of every branch the user works in), newest first: those spent between
     * `from` and `to` (default this month), or with `status=unpaid` everything still owed. The response
     * carries the total of the listed expenses.
     */
    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::ExpensesView->value);

        $request->validate([
            'branch_id' => ['sometimes', 'nullable', 'uuid'],
            'from' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'to' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'after_or_equal:from'],
            'status' => ['sometimes', 'in:all,unpaid'],
            'supplier_id' => ['sometimes', 'nullable', 'uuid'],
        ]);

        $branchIds = $this->branchIds($request);
        $today = now($request->user()->tenant->timezone);
        $unpaid = $request->input('status') === 'unpaid';

        $query = Expense::query()
            ->whereIn('branch_id', $branchIds)
            ->when($request->filled('supplier_id'), fn (Builder $query) => $query->where('supplier_id', $request->input('supplier_id')))
            ->when(
                $unpaid,
                fn (Builder $query) => $query->whereNull('paid_at'),
                fn (Builder $query) => $query
                    ->where('spent_on', '>=', $request->input('from', $today->copy()->startOfMonth()->toDateString()))
                    ->where('spent_on', '<=', $request->input('to', $today->toDateString())),
            );

        $total = (int) (clone $query)->sum('amount');
        $expenses = $query->with(self::RELATIONS)->latest('spent_on')->latest()->limit(500)->get();

        return response()->json([
            'data' => ExpenseResource::collection($expenses),
            'total' => $total,
        ]);
    }

    public function store(StoreExpenseRequest $request, RecordExpense $recordExpense): JsonResponse
    {
        return ExpenseResource::make($recordExpense->handle($request->user(), $request->validated())->load(self::RELATIONS))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    /**
     * Pay an expense that is still owed.
     */
    public function pay(Request $request, Expense $expense, PayExpense $payExpense): ExpenseResource
    {
        Gate::authorize('pay', $expense);

        $request->validate(['payment_method' => ['required', Rule::enum(ExpensePaymentMethod::class)]]);

        return ExpenseResource::make(
            $payExpense->handle($request->user(), $expense, ExpensePaymentMethod::from($request->input('payment_method')))->load(self::RELATIONS),
        );
    }

    public function destroy(Request $request, Expense $expense, DeleteExpense $deleteExpense): Response
    {
        Gate::authorize('delete', $expense);

        $deleteExpense->handle($request->user(), $expense);

        return response()->noContent();
    }

    /**
     * The requested branch, or every branch the user works in.
     *
     * @return list<string>
     */
    private function branchIds(Request $request): array
    {
        if (! $request->filled('branch_id')) {
            return $request->user()->accessibleBranches()->modelKeys();
        }

        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        return [$branch->id];
    }
}
