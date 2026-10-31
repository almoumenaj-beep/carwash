<?php

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\Models\Service;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Creates or edits a service. When prices are given they replace the service's whole price list,
 * and every price change is audited.
 */
class SaveService
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{service_category_id?: ?string, name: string, description?: ?string, duration_minutes?: int, is_addon?: bool, sort_order?: int, is_active?: bool, prices?: list<array{vehicle_size_id?: ?string, branch_id?: ?string, price: int}>}  $data
     *
     * @throws ValidationException
     */
    public function create(User $actor, array $data): Service
    {
        return $this->save($actor, new Service, $data, 'service.created');
    }

    /**
     * @param  array{service_category_id?: ?string, name?: string, description?: ?string, duration_minutes?: int, is_addon?: bool, sort_order?: int, is_active?: bool, prices?: list<array{vehicle_size_id?: ?string, branch_id?: ?string, price: int}>}  $data
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
        unset($data['prices']);

        return DB::transaction(function () use ($actor, $service, $data, $prices, $event): Service {
            $service->fill($data);
            $changes = array_keys($service->getDirty());
            $service->save();

            if ($prices !== null) {
                $service->prices()->delete();
                $service->prices()->createMany($prices);
                $changes[] = 'prices';
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
