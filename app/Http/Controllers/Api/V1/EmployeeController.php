<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Expenses\Enums\ExpensePaymentMethod;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Staff\Actions\RecordDailyWage;
use App\Domain\Staff\Enums\CommissionType;
use App\Domain\Staff\Enums\SalaryType;
use App\Domain\Staff\Models\EmployeeProfile;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

/**
 * Staff as employees: pay terms and ad-hoc daily wages. Seen with employees.view (staff who share a
 * branch with the user, or everyone for all-branch users); pay terms and daily wages change with
 * employees.manage. Amounts in minor units.
 */
class EmployeeController extends Controller
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::EmployeesView->value);

        $actor = $request->user();
        $actorBranches = $actor->accessibleBranches()->modelKeys();

        $staff = User::query()
            ->where('tenant_id', $actor->tenant_id)
            ->where('is_active', true)
            ->with(['roles', 'branches:id'])
            ->orderBy('name')
            ->get()
            ->filter(fn (User $member) => $actor->hasAllBranchAccess()
                || $member->hasAllBranchAccess()
                || $member->branches->pluck('id')->intersect($actorBranches)->isNotEmpty())
            ->values();

        $ids = $staff->modelKeys();
        $profiles = EmployeeProfile::query()->whereIn('user_id', $ids)->get()->keyBy('user_id');

        $today = now($actor->tenant->timezone);
        $dailyWages = Expense::query()
            ->whereIn('employee_id', $ids)
            ->where('spent_on', '>=', $today->copy()->startOfMonth()->toDateString())
            ->where('spent_on', '<=', $today->toDateString())
            ->groupBy('employee_id')
            ->selectRaw('SUM(amount) as total, employee_id')
            ->pluck('total', 'employee_id');

        return response()->json(['data' => $staff->map(fn (User $member) => [
            'id' => $member->id,
            'name' => $member->name,
            'roles' => $member->roles->map->label()->values(),
            'monthly_salary' => $profiles->get($member->id)?->monthly_salary ?? 0,
            'salary_type' => $profiles->get($member->id)?->salary_type ?? SalaryType::Monthly,
            'commission_type' => $profiles->get($member->id)?->commission_type ?? CommissionType::None,
            'commission_value' => $profiles->get($member->id)?->commission_value ?? 0,
            'daily_wages_this_month' => (int) ($dailyWages[$member->id] ?? 0),
        ])]);
    }

    /**
     * Set a staff member's salary type, salary amount and commission.
     */
    public function updateProfile(Request $request, User $user): JsonResponse
    {
        Gate::authorize(Permission::EmployeesManage->value);
        abort_unless($user->tenant_id === $request->user()->tenant_id, 404);

        $validated = $request->validate([
            'monthly_salary' => ['required', 'integer', 'between:0,100000000'],
            'salary_type' => ['sometimes', Rule::enum(SalaryType::class)],
            'commission_type' => ['required', Rule::enum(CommissionType::class)],
            'commission_value' => [
                'required', 'integer', 'min:0',
                $request->input('commission_type') === CommissionType::Percent->value ? 'max:10000' : 'max:100000000',
            ],
        ]);
        $validated['salary_type'] ??= SalaryType::Monthly;

        $profile = EmployeeProfile::query()->updateOrCreate(['user_id' => $user->id], $validated);
        $this->auditTrail->record('employee.pay_terms_changed', $profile, $request->user(), 'Pay terms changed', $validated);

        return response()->json(['data' => [
            'user_id' => $user->id,
            'monthly_salary' => $profile->monthly_salary,
            'salary_type' => $profile->salary_type,
            'commission_type' => $profile->commission_type,
            'commission_value' => $profile->commission_value,
        ]]);
    }

    /**
     * Pays a daily-paid staff member for a day: records the money out as a wages expense linked to them.
     * The amount is whatever was agreed that day.
     */
    public function recordDailyWage(Request $request, User $user, RecordDailyWage $recordDailyWage): JsonResponse
    {
        Gate::authorize(Permission::EmployeesManage->value);
        abort_unless($user->tenant_id === $request->user()->tenant_id, 404);

        $validated = $request->validate([
            'branch_id' => ['required', 'uuid'],
            'amount' => ['required', 'integer', 'between:1,100000000'],
            'spent_on' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'payment_method' => ['nullable', Rule::enum(ExpensePaymentMethod::class)],
            'expense_category_id' => ['nullable', 'uuid'],
        ]);

        $expense = DB::transaction(fn () => $recordDailyWage->handle($request->user(), $user, $validated));

        return response()->json(['data' => ['expense_id' => $expense->id, 'amount' => $expense->amount]], 201);
    }
}
