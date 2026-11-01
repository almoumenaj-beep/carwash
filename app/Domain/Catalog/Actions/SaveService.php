<?php

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\Models\Service;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Creates or edits a service or package. When prices (or a package's services) are given they replace
 * the whole list,
 * and every price change is audited.
 */
class SaveService
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{service_category_id?: ?string, name: string, description?: ?string, duration_minutes?: int, is_addon?: bool, is_package?: bool, package_service_ids?: list<string>, sort_order?: int, is_active?: bool, prices?: list<array{vehicle_size_id?: ?string, branch_id?: ?string, price: int}>}  $data
     *
     * @throws ValidationException
     */
    public function create(User $actor, array $data): Service
    {
        return $this->save($actor, new Service, $data, 'service.created');
    }

    /**
     * @param  array{service_category_id?: ?string, name?: string, description?: ?string, duration_minutes?: int, is_addon?: bool, is_package?: bool, package_service_ids?: list<string>, sort_order?: int, is_active?: bool, prices?: list<array{vehicle_size_id?: ?string, branch_id?: ?string, price: int}>}  $data
     *
     * @throws ValidationException
     */
    public function update(User $actor, Service $service, array $data): Service
    {
        return $this->save($actor, $service, $data, 'service.updated');
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function save(User $actor, Service $service, array $data, string $event): Service
    {
        $prices = array_key_exists('prices', $data) ? $this->normalisedPrices($data['prices']) : null;
        $packageServiceIds = $data['package_service_ids'] ?? null;
        unset($data['prices'], $data['package_service_ids']);

        $service->fill($data);
        $this->ensureValidPackage($service, $packageServiceIds);

        if ($service->is_package) {
            $service->service_category_id = null;
        } else {
            $service->forceFill(['package_discount_type' => null, 'package_discount_value' => 0]);
        }

        return DB::transaction(function () use ($actor, $service, $prices, $packageServiceIds, $event): Service {
            $changes = array_keys($service->getDirty());
            $service->save();

            if ($service->is_package) {
                $service->prices()->delete();
            } elseif ($prices !== null) {
                $service->prices()->delete();
                $service->prices()->createMany($prices);
                $changes[] = 'prices';
            }

            if (! $service->is_package) {
                $service->packageItems()->detach();
            } elseif ($packageServiceIds !== null) {
                $service->packageItems()->sync(collect($packageServiceIds)->mapWithKeys(
                    fn (string $id, int $order) => [$id => ['sort_order' => $order]],
                )->all());
                $changes[] = 'package_items';
            }

            if ($changes !== [] || $event === 'service.created') {
                $this->auditTrail->record($event, $service, $actor, 'Service saved', [
                    'changed' => $changes,
                    'prices' => $prices,
                ]);
            }

            return $service;
        });
    }

    /**
     * A package is a main service bundling at least two other services (not packages themselves),
     * priced from them less its discount, so it has no price list of its own.
     *
     * @param  list<string>|null  $packageServiceIds
     *
     * @throws ValidationException
     */
    private function ensureValidPackage(Service $service, ?array $packageServiceIds): void
    {
        if (! $service->is_package) {
            return;
        }

        if ($service->is_addon) {
            throw ValidationException::withMessages(['is_package' => __('A package cannot be an add-on.')]);
        }

        $ids = $packageServiceIds ?? ($service->exists ? $service->packageItems()->pluck('services.id')->all() : []);
        $valid = Service::query()->whereKey($ids)->whereKeyNot($service->getKey() ?? '')->where('is_package', false)->count();

        if (count($ids) < 2 || $valid !== count($ids)) {
            throw ValidationException::withMessages([
                'package_service_ids' => __('A package includes at least two services, and no other packages.'),
            ]);
        }
    }

    /**
     * One price per (size, branch) combination; null means "every size" / "every branch".
     *
     * @param  list<array{vehicle_size_id?: ?string, branch_id?: ?string, price: int}>  $prices
     * @return list<array{vehicle_size_id: ?string, branch_id: ?string, price: int}>
     *
     * @throws ValidationException
     */
    private function normalisedPrices(array $prices): array
    {
        $normalised = [];

        foreach ($prices as $price) {
            $key = ($price['vehicle_size_id'] ?? '*').'|'.($price['branch_id'] ?? '*');

            if (isset($normalised[$key])) {
                throw ValidationException::withMessages([
                    'prices' => __('Each vehicle size can have only one price per branch.'),
                ]);
            }

            $normalised[$key] = [
                'vehicle_size_id' => $price['vehicle_size_id'] ?? null,
                'branch_id' => $price['branch_id'] ?? null,
                'price' => (int) $price['price'],
            ];
        }

        return array_values($normalised);
    }
}
