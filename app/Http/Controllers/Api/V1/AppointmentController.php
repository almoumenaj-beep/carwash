<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Appointments\Actions\BookAppointment;
use App\Domain\Appointments\Actions\CheckInAppointment;
use App\Domain\Appointments\Enums\AppointmentStatus;
use App\Domain\Appointments\Models\Appointment;
use App\Domain\Appointments\Support\AppointmentSchedule;
use App\Domain\Catalog\Models\Service;
use App\Domain\Identity\Enums\Permission;
use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Branch;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveAppointmentRequest;
use App\Http\Requests\StoreOrderRequest;
use App\Http\Resources\OrderResource;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

/**
 * Cars booked to come in. The day's bookings and free times are seen by staff who book cars
 * (appointments.manage) or check them in (orders.create); booking, changing, cancelling and marking a
 * no-show need appointments.manage; checking a booked car in is a check-in like any other.
 */
class AppointmentController extends Controller
{
    private const RELATIONS = ['customer', 'vehicleSize', 'order', 'creator'];

    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * A branch's bookings on a day (`date`, default today), earliest first.
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ]);
        $branch = $this->viewableBranch($request);
        $day = $this->day($request);

        $appointments = Appointment::query()
            ->where('branch_id', $branch->id)
            ->where('starts_at', '>=', $day->utc())
            ->where('starts_at', '<', $day->addDay()->utc())
            ->with(self::RELATIONS)
            ->orderBy('starts_at')
            ->get();

        return response()->json(['data' => $this->presentAll($appointments, $request)]);
    }

    /**
     * The times on a day when a visit of `minutes` can still be booked; `appointment_id` leaves that
     * booking's own place free while it is moved.
     */
    public function slots(Request $request, AppointmentSchedule $schedule): JsonResponse
    {
        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'date' => ['required', 'date_format:Y-m-d'],
            'minutes' => ['required', 'integer', 'between:1,720'],
            'appointment_id' => ['sometimes', 'nullable', 'uuid'],
        ]);
        $branch = $this->viewableBranch($request);

        return response()->json([
            'data' => $schedule->slots($branch, $this->day($request), max((int) $request->input('minutes'), BookAppointment::MINIMUM_MINUTES), $request->input('appointment_id')),
            'meta' => ['capacity' => $schedule->capacity($branch)],
        ]);
    }

    public function store(SaveAppointmentRequest $request, BookAppointment $bookAppointment): JsonResponse
    {
        $appointment = $bookAppointment->handle($request->user(), $request->validated());

        return response()->json(['data' => $this->presentAll(collect([$appointment->load(self::RELATIONS)]), $request)[0]], Response::HTTP_CREATED);
    }

    public function update(SaveAppointmentRequest $request, Appointment $appointment, BookAppointment $bookAppointment): JsonResponse
    {
        $this->ensureBooked($appointment);
        $appointment = $bookAppointment->handle($request->user(), $request->validated(), $appointment);

        return response()->json(['data' => $this->presentAll(collect([$appointment->load(self::RELATIONS)]), $request)[0]]);
    }

    public function cancel(Request $request, Appointment $appointment): JsonResponse
    {
        $this->authorizeManaging($request, $appointment);
        $request->validate(['reason' => ['nullable', 'string', 'max:255']]);
        $this->ensureBooked($appointment);

        $appointment->forceFill(['status' => AppointmentStatus::Cancelled, 'cancel_reason' => $request->input('reason')])->save();
        $this->auditTrail->record('appointment.cancelled', $appointment, $request->user(), 'Appointment cancelled', ['reason' => $request->input('reason')]);

        return response()->json(['data' => $this->presentAll(collect([$appointment->load(self::RELATIONS)]), $request)[0]]);
    }

    /**
     * The car did not come; only once its time has come.
     */
    public function noShow(Request $request, Appointment $appointment): JsonResponse
    {
        $this->authorizeManaging($request, $appointment);
        $this->ensureBooked($appointment);
        if ($appointment->starts_at->isFuture()) {
            throw ValidationException::withMessages(['appointment' => __('A booking can be marked as a no-show once its time has come.')]);
        }

        $appointment->forceFill(['status' => AppointmentStatus::NoShow])->save();
        $this->auditTrail->record('appointment.no_show', $appointment, $request->user(), 'Booked car did not come');

        return response()->json(['data' => $this->presentAll(collect([$appointment->load(self::RELATIONS)]), $request)[0]]);
    }

    /**
     * The booked car arrived: it is checked in with the same details as at the counter.
     */
    public function checkIn(StoreOrderRequest $request, Appointment $appointment, CheckInAppointment $checkInAppointment): JsonResponse
    {
        $order = $checkInAppointment->handle($request->user(), $appointment, $request->validated());

        return OrderResource::make($order->load(OrderController::RELATIONS))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    private function viewableBranch(Request $request): Branch
    {
        Gate::authorize('viewAny', Appointment::class);
        $branch = Branch::query()->findOrFail($request->input('branch_id'));
        Gate::authorize('view', $branch);

        return $branch;
    }

    private function authorizeManaging(Request $request, Appointment $appointment): void
    {
        abort_unless(
            $request->user()->can(Permission::AppointmentsManage->value) && $request->user()->canAccessBranch($appointment->branch),
            Response::HTTP_FORBIDDEN,
        );
    }

    /**
     * @throws ValidationException
     */
    private function ensureBooked(Appointment $appointment): void
    {
        if (! $appointment->isBooked()) {
            throw ValidationException::withMessages(['appointment' => __('This booking is no longer waiting for the car.')]);
        }
    }

    private function day(Request $request): CarbonImmutable
    {
        $timezone = $request->user()->tenant->timezone;

        return $request->filled('date')
            ? CarbonImmutable::createFromFormat('Y-m-d', $request->input('date'), $timezone)->startOfDay()
            : CarbonImmutable::now($timezone)->startOfDay();
    }

    /**
     * @param  Collection<int, Appointment>  $appointments
     * @return list<array<string, mixed>>
     */
    private function presentAll(Collection $appointments, Request $request): array
    {
        $services = Service::query()
            ->whereKey($appointments->flatMap(fn (Appointment $appointment) => array_column($appointment->items, 'service_id'))->unique()->values())
            ->pluck('name', 'id');
        $timezone = $request->user()->tenant->timezone;

        return $appointments->map(fn (Appointment $appointment) => [
            'id' => $appointment->id,
            'branch_id' => $appointment->branch_id,
            'starts_at' => $appointment->starts_at->setTimezone($timezone)->toIso8601String(),
            'ends_at' => $appointment->ends_at->setTimezone($timezone)->toIso8601String(),
            'status' => $appointment->status,
            'customer' => $appointment->customer === null ? null : [
                'id' => $appointment->customer->id,
                'name' => $appointment->customer->name,
                'phone' => $appointment->customer->phone,
            ],
            'customer_name' => $appointment->customer_name,
            'customer_phone' => $appointment->customer_phone,
            'vehicle_id' => $appointment->vehicle_id,
            'plate_number' => $appointment->plate_number,
            'vehicle_size' => $appointment->vehicleSize === null ? null : ['id' => $appointment->vehicleSize->id, 'name' => $appointment->vehicleSize->name],
            'items' => array_map(fn (array $item) => [...$item, 'name' => $services[$item['service_id']] ?? '—'], $appointment->items),
            'estimated_total' => $appointment->estimated_total,
            'notes' => $appointment->notes,
            'cancel_reason' => $appointment->cancel_reason,
            'order' => $appointment->order === null ? null : ['id' => $appointment->order->id, 'number' => $appointment->order->number],
            'created_by' => ['id' => $appointment->creator->id, 'name' => $appointment->creator->name],
        ])->values()->all();
    }
}
