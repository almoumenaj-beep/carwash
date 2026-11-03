<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Staff\Enums\CommissionType;
use App\Domain\Staff\Models\AttendanceLog;
use App\Domain\Staff\Models\EmployeeProfile;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

/**
 * Staff as employees: pay terms, and whether they are clocked in now. Seen with
 * employees.view (staff who share a branch with the user, or everyone for all-branch users); pay terms
 * change with employees.manage. Amounts in minor units.
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
        $open = AttendanceLog::query()->whereIn('user_id', $ids)->whereNull('clock_out_at')->get()->keyBy('user_id');

        return response()->json(['data' => $staff->map(fn (User $member) => [
            'id' => $member->id,
            'name' => $member->name,
            'roles' => $member->roles->map->label()->values(),
            'monthly_salary' => $profiles->get($member->id)?->monthly_salary ?? 0,
            'commission_type' => $profiles->get($member->id)?->commission_type ?? CommissionType::None,
            'commission_value' => $profiles->get($member->id)?->commission_value ?? 0,
            'clocked_in_at' => $open->get($member->id)?->clock_in_at?->toIso8601String(),
        ])]);
    }

    /**
     * Set a staff member's salary and commission.
     */
    public function updateProfile(Request $request, User $user): JsonResponse
    {
        Gate::authorize(Permission::EmployeesManage->value);
        abort_unless($user->tenant_id === $request->user()->tenant_id, 404);

        $validated = $request->validate([
            'monthly_salary' => ['required', 'integer', 'between:0,100000000'],
            'commission_type' => ['required', Rule::enum(CommissionType::class)],
            'commission_value' => [
                'required', 'integer', 'min:0',
                $request->input('commission_type') === CommissionType::Percent->value ? 'max:10000' : 'max:100000000',
            ],
        ]);

        $profile = EmployeeProfile::query()->updateOrCreate(['user_id' => $user->id], $validated);
        $this->auditTrail->record('employee.pay_terms_changed', $profile, $request->user(), 'Pay terms changed', $validated);

        return response()->json(['data' => [
            'user_id' => $user->id,
            'monthly_salary' => $profile->monthly_salary,
            'commission_type' => $profile->commission_type,
            'commission_value' => $profile->commission_value,
        ]]);
    }
}
