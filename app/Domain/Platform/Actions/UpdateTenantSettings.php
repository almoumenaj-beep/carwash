<?php

namespace App\Domain\Platform\Actions;

use App\Domain\Platform\Audit\AuditTrail;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;

/**
 * Updates the car wash's own settings. The currency is fixed at onboarding: changing it
 * would reinterpret every stored amount.
 */
class UpdateTenantSettings
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{name?: string, locale?: string, timezone?: string, vat_rate?: float|int, prices_include_vat?: bool, vat_number?: ?string}  $data
     */
    public function handle(User $actor, Tenant $tenant, array $data): Tenant
    {
        if (array_key_exists('vat_rate', $data)) {
            $data['vat_rate_bps'] = (int) round($data['vat_rate'] * 100);
            unset($data['vat_rate']);
        }

        $tenant->fill($data);
        $changes = array_keys($tenant->getDirty());

        if ($changes !== []) {
            $tenant->save();

            $this->auditTrail->record('settings.updated', $tenant, $actor, 'Car wash settings updated', [
                'changed' => $changes,
            ]);
        }

        return $tenant;
    }
}
