<?php

namespace App\Domain\Orders\Support;

use App\Domain\Catalog\Models\Service;
use App\Domain\Catalog\Models\VehicleSize;
use App\Domain\Platform\Models\Branch;
use Illuminate\Validation\ValidationException;

/**
 * Prices the services of a work order on the server, from the catalog: the price for the car's
 * size at this branch, frozen on the order. Add-ons are only sold with a main service; a package
 * (a main service) carries the services it includes as `components`.
 */
class OrderPricing
{
    /**
     * @param  list<array{service_id: string, quantity?: int}>  $items
     * @return array{lines: list<array{service_id: string, name: string, is_addon: bool, is_package: bool, quantity: int, unit_price: int, line_total: int, duration_minutes: int, components: list<array{service_id: string, name: string}>}>, subtotal: int, minutes: int}
     *
     * @throws ValidationException
     */
    public function price(Branch $branch, ?VehicleSize $size, array $items): array
    {
        $services = Service::query()
            ->with(['prices', 'packageItems.prices'])
            ->whereKey(array_column($items, 'service_id'))
            ->get()
            ->keyBy('id');
        $lines = [];
        $errors = [];

        foreach ($items as $index => $item) {
            $service = $services->get($item['service_id']);

            if ($service === null || ! $service->is_active) {
                $errors["items.{$index}.service_id"] = __('This service is not available.');

                continue;
            }

            $unitPrice = $service->priceFor($size, $branch);

            if ($unitPrice === null) {
                $errors["items.{$index}.service_id"] = __(':service has no price for this vehicle size.', ['service' => $service->name]);

                continue;
            }

            $quantity = (int) ($item['quantity'] ?? 1);
            $components = $service->is_package ? $service->packageItems : collect();
            $minutes = $service->is_package && $service->duration_minutes === 0
                ? $components->sum('duration_minutes')
                : $service->duration_minutes;

            $lines[] = [
                'service_id' => $service->id,
                'name' => $service->name,
                'is_addon' => $service->is_addon,
                'is_package' => $service->is_package,
                'quantity' => $quantity,
                'unit_price' => $unitPrice,
                'line_total' => $unitPrice * $quantity,
                'duration_minutes' => $minutes * $quantity,
                'components' => $components->map(fn (Service $component) => [
                    'service_id' => $component->id,
                    'name' => $component->name,
                ])->values()->all(),
            ];
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }

        if (! collect($lines)->contains(fn (array $line) => ! $line['is_addon'])) {
            throw ValidationException::withMessages(['items' => __('Add at least one main service; add-ons are sold with one.')]);
        }

        return [
            'lines' => $lines,
            'subtotal' => array_sum(array_column($lines, 'line_total')),
            'minutes' => array_sum(array_column($lines, 'duration_minutes')),
        ];
    }
}
