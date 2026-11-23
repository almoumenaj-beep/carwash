<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Offers\Models\Offer;
use App\Domain\Platform\Audit\AuditTrail;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * The offers shown on the car wash's public customer page. Managed by the owner (settings.manage).
 * Amounts in minor units.
 */
class OfferController extends Controller
{
    public function __construct(private AuditTrail $auditTrail) {}

    public function index(Request $request): JsonResponse
    {
        Gate::authorize(Permission::SettingsManage->value);

        return response()->json(['data' => Offer::query()->orderByDesc('created_at')->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        Gate::authorize(Permission::SettingsManage->value);

        $validated = array_filter($request->validate(self::rules()), fn (mixed $value) => $value !== null);
        $offer = new Offer($validated);
        $offer->save();

        $this->auditTrail->record('offer.created', $offer, $request->user(), 'Offer created', ['title' => $offer->title]);

        return response()->json(['data' => $offer], Response::HTTP_CREATED);
    }

    public function update(Request $request, Offer $offer): JsonResponse
    {
        Gate::authorize(Permission::SettingsManage->value);

        $validated = array_filter($request->validate(self::rules()), fn (mixed $value) => $value !== null);
        $offer->update($validated);

        $this->auditTrail->record('offer.updated', $offer, $request->user(), 'Offer updated', ['title' => $offer->title]);

        return response()->json(['data' => $offer]);
    }

    public function destroy(Request $request, Offer $offer): Response
    {
        Gate::authorize(Permission::SettingsManage->value);

        $offer->delete();

        return response()->noContent();
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    private static function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:1000'],
            'price' => ['nullable', 'integer', 'between:0,100000000'],
            'expires_on' => ['nullable', 'date_format:Y-m-d'],
            'is_active' => ['sometimes', 'nullable', 'boolean'],
        ];
    }
}
