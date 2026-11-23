<?php

namespace App\Http\Controllers;

use App\Domain\Appointments\Actions\BookAppointment;
use App\Domain\Appointments\Models\Appointment;
use App\Domain\Appointments\Support\AppointmentSchedule;
use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Crm\Support\PhoneNumber;
use App\Domain\Offers\Models\Offer;
use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Platform\Tenancy\TenantContext;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * The car wash's public customer page at /w/{slug}: the services with their prices, the current offers,
 * and a booking form that books a real appointment, exactly as if reception had typed it. No sign-in:
 * the tenant comes from the address, and a TenantContext is opened around every query.
 */
class CustomerPageController extends Controller
{
    public function __construct(private TenantContext $tenancy) {}

    public function show(Tenant $tenant): View
    {
        abort_unless($tenant->isActive(), 404);

        return view('customer.show', $this->tenancy->run($tenant, fn (): array => [
            'tenant' => $tenant,
            'branches' => Branch::query()->where('is_active', true)->orderBy('name')->get(),
            'sizes' => VehicleSize::query()->where('is_active', true)->orderBy('sort_order')->get(),
            'services' => $this->services($tenant),
            'offers' => Offer::query()->visible(CarbonImmutable::today($tenant->timezone))->orderByDesc('created_at')->get(),
        ]));
    }

    /**
     * The bookable start times for a branch and day, for the booking form's time picker.
     */
    public function slots(Request $request, Tenant $tenant): JsonResponse
    {
        abort_unless($tenant->isActive(), 404);

        $request->validate([
            'branch_id' => ['required', 'uuid'],
            'date' => ['required', 'date_format:Y-m-d'],
        ]);

        return $this->tenancy->run($tenant, function () use ($request, $tenant): JsonResponse {
            $branch = Branch::query()->findOrFail($request->input('branch_id'));
            $day = CarbonImmutable::createFromFormat('Y-m-d', $request->input('date'), $tenant->timezone)->startOfDay();

            return response()->json([
                'data' => app(AppointmentSchedule::class)->slots($branch, $day, BookAppointment::MINIMUM_MINUTES),
            ]);
        });
    }

    /**
     * Books the appointment; on success the page reloads with a confirmation, on failure the errors
     * go back to the form.
     */
    public function book(Request $request, Tenant $tenant, BookAppointment $bookAppointment): RedirectResponse
    {
        abort_unless($tenant->isActive(), 404);

        $validated = $request->validate([
            'customer_name' => ['required', 'string', 'max:100'],
            'customer_phone' => ['required', 'string', 'max:30'],
            'branch_id' => ['required', 'uuid'],
            'vehicle_size_id' => ['nullable', 'uuid'],
            'service_id' => ['nullable', 'uuid'],
            'plate_number' => ['nullable', 'string', 'max:20'],
            'starts_at' => ['required', 'date_format:Y-m-d\TH:i'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);
        $validated['customer_phone'] = PhoneNumber::normalise($validated['customer_phone']);

        $data = [
            'branch_id' => $validated['branch_id'],
            'starts_at' => $validated['starts_at'],
            'customer_phone' => $validated['customer_phone'],
            'customer_name' => $validated['customer_name'],
            'vehicle_size_id' => $validated['vehicle_size_id'] ?? null,
            'plate_number' => $validated['plate_number'] ?? null,
            'items' => isset($validated['service_id']) ? [['service_id' => $validated['service_id']]] : [],
            'notes' => $validated['notes'] ?? null,
        ];

        try {
            $this->tenancy->run($tenant, fn () => $bookAppointment->handle(null, $data));
        } catch (ValidationException $exception) {
            return redirect()->route('customer.page', $tenant)->withErrors($exception->errors())->withInput();
        }

        return redirect()->route('customer.page', $tenant)->with('booked', __('Your appointment is booked. We will see you then!'));
    }

    /**
     * The active services with the price of every vehicle size, grouped by category for the price list.
     *
     * @return list<array{category: string, services: list<array{id: string, name: string, description: ?string, duration_minutes: int, prices: list<array{size: string, price: int}>}>}>
     */
    private function services(Tenant $tenant): array
    {
        $branch = Branch::query()->where('is_active', true)->orderBy('name')->first();
        $sizes = VehicleSize::query()->where('is_active', true)->orderBy('sort_order')->get();
        $services = Service::query()
            ->where('is_active', true)
            ->where('is_addon', false)
            ->with(['category', 'prices', 'packageItems.prices'])
            ->orderBy('sort_order')
            ->get();

        $groups = [];
        foreach ($services as $service) {
            $prices = [];
            foreach ($sizes as $size) {
                $price = $service->priceFor($size, $branch);
                if ($price !== null) {
                    $prices[] = ['size' => $size->name, 'price' => $price];
                }
            }

            $category = $service->category->name ?? '';
            $groups[$category] ??= ['category' => $category, 'services' => []];
            $groups[$category]['services'][] = [
                'id' => $service->id,
                'name' => $service->name,
                'description' => $service->description,
                'duration_minutes' => $service->duration_minutes,
                'prices' => $prices,
            ];
        }

        return array_values($groups);
    }
}
