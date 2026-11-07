<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Crm\Models\Customer;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Memberships\Actions\SellMembership;
use App\Domain\Memberships\Models\CustomerMembership;
use App\Domain\Memberships\Models\MembershipPlan;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Domain\Sales\Enums\PaymentMethod;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveMembershipPlanRequest;
use App\Http\Requests\SellMembershipRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

/**
 * Membership plans, set with services.manage and seen by staff who sell them, and the memberships customers
 * bought: seen with customers.view, sold with pos.checkout, and stopped by the owner or a branch manager.
 */
class MembershipController extends Controller
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function plans(Request $request): JsonResponse
    {
        abort_unless(Gate::any([Permission::ServicesManage->value, Permission::PosCheckout->value]), Response::HTTP_FORBIDDEN);

        return response()->json(['data' => MembershipPlan::query()->orderBy('name')->get()->map($this->presentPlan(...))->values()]);
    }

    public function storePlan(SaveMembershipPlanRequest $request): JsonResponse
    {
        $plan = MembershipPlan::query()->create($request->validated());
        $this->auditTrail->record('membership_plan.created', $plan, $request->user(), 'Membership plan added');

        return response()->json(['data' => $this->presentPlan($plan)], Response::HTTP_CREATED);
    }

    public function updatePlan(SaveMembershipPlanRequest $request, MembershipPlan $plan): JsonResponse
    {
        $plan->fill($request->validated());
        $changed = array_keys($plan->getDirty());
        $plan->save();
        $this->auditTrail->record('membership_plan.updated', $plan, $request->user(), 'Membership plan changed', ['changed' => $changed]);

        return response()->json(['data' => $this->presentPlan($plan)]);
    }

    /**
     * The customer's memberships, newest first.
     */
    public function index(Customer $customer): JsonResponse
    {
        Gate::authorize(Permission::CustomersView->value);

        $memberships = CustomerMembership::query()
            ->where('customer_id', $customer->id)
            ->with(['vehicle', 'invoice.payments'])
            ->latest()
            ->get();

        return response()->json(['data' => $memberships->map($this->present(...))->values()]);
    }

    public function sell(SellMembershipRequest $request, Customer $customer, SellMembership $sellMembership): JsonResponse
    {
        $branch = Branch::query()->findOrFail($request->validated('branch_id'));
        Gate::authorize('view', $branch);

        $membership = $sellMembership->handle(
            $request->user(),
            $customer,
            MembershipPlan::query()->findOrFail($request->validated('membership_plan_id')),
            $branch,
            PaymentMethod::from($request->validated('method')),
            $request->validated('vehicle_id'),
        );

        return response()->json(['data' => $this->present($membership->load('vehicle'))], Response::HTTP_CREATED);
    }

    /**
     * Stop a membership: no more washes can be taken from it. No money is returned here.
     */
    public function cancel(Request $request, CustomerMembership $membership): JsonResponse
    {
        Gate::authorize(Permission::PosCloseShift->value);
        Gate::authorize(Permission::ReportsSales->value);

        if ($membership->cancelled_at !== null) {
            throw ValidationException::withMessages(['membership' => __('This membership is already stopped.')]);
        }

        $membership->forceFill(['cancelled_at' => now(), 'cancelled_by' => $request->user()->id])->save();
        $this->auditTrail->record('membership.cancelled', $membership, $request->user(), 'Membership stopped');

        return response()->json(['data' => $this->present($membership->load('vehicle'))]);
    }

    /**
     * @return array<string, mixed>
     */
    private function presentPlan(MembershipPlan $plan): array
    {
        return [
            'id' => $plan->id,
            'name' => $plan->name,
            'price' => $plan->price,
            'washes' => $plan->washes,
            'validity_days' => $plan->validity_days,
            'scope' => $plan->scope,
            'service_ids' => $plan->service_ids,
            'is_active' => $plan->is_active,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function present(CustomerMembership $membership): array
    {
        return [
            'id' => $membership->id,
            'name' => $membership->name,
            'washes' => $membership->washes,
            'washes_left' => $membership->washesLeft(),
            'service_ids' => $membership->service_ids,
            'vehicle' => $membership->vehicle === null ? null : ['id' => $membership->vehicle->id, 'plate_number' => $membership->vehicle->plate_number],
            'expires_at' => $membership->expires_at->toIso8601String(),
            'is_usable' => $membership->isUsable(),
            'is_cancelled' => $membership->cancelled_at !== null,
            'invoice_id' => $membership->invoice_id,
            'invoice_total' => $membership->invoice->total,
            'invoice_method' => $membership->invoice->payments->first()?->method,
            'can_refund' => $membership->cancelled_at === null && $membership->washes_used === 0,
        ];
    }
}
