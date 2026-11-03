<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Models\Branch;
use App\Domain\Staff\Actions\GiveSalaryAdvance;
use App\Domain\Staff\Models\SalaryAdvance;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

/**
 * Salary advances: given with employees.manage at a branch the user works in, seen with employees.view.
 */
class SalaryAdvanceController extends Controller
{
    /**
     * The latest advances, optionally for one staff member, newest first.
     */
    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::EmployeesView->value);
        $request->validate(['user_id' => ['sometimes', 'nullable', 'uuid']]);

        $advances = SalaryAdvance::query()
            ->whereIn('branch_id', $request->user()->accessibleBranches()->modelKeys())
            ->when($request->filled('user_id'), fn ($query) => $query->where('user_id', $request->input('user_id')))
            ->with('user')
            ->latest('given_on')
            ->latest()
            ->limit(100)
            ->get();

        return response()->json(['data' => $advances->map($this->present(...))]);
    }

    public function store(Request $request, GiveSalaryAdvance $giveSalaryAdvance): JsonResponse
    {
        Gate::authorize(Permission::EmployeesManage->value);

        $tenantId = $request->user()->tenant_id;
        $validated = $request->validate([
            'user_id' => ['required', 'uuid', Rule::exists('users', 'id')->where('tenant_id', $tenantId)],
            'branch_id' => ['required', 'uuid'],
            'amount' => ['required', 'integer', 'between:1,100000000'],
            'expense_category_id' => ['required', 'uuid', Rule::exists('expense_categories', 'id')->where('tenant_id', $tenantId)],
            'payment_method' => ['required', Rule::enum(ExpensePaymentMethod::class)],
            'note' => ['nullable', 'string', 'max:255'],
        ]);

        Gate::authorize('view', Branch::query()->findOrFail($validated['branch_id']));

        $advance = $giveSalaryAdvance->handle($request->user(), User::query()->findOrFail($validated['user_id']), $validated);

        return response()->json(['data' => $this->present($advance->load('user'))], 201);
    }

    /**
     * @return array<string, mixed>
     */
    private function present(SalaryAdvance $advance): array
    {
        return [
            'id' => $advance->id,
            'user' => ['id' => $advance->user->id, 'name' => $advance->user->name],
            'branch_id' => $advance->branch_id,
            'amount' => $advance->amount,
            'given_on' => $advance->given_on->toDateString(),
            'note' => $advance->note,
            'is_deducted' => $advance->isDeducted(),
        ];
    }
}
