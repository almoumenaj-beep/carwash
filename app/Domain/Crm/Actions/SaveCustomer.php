<?php

namespace App\Domain\Crm\Actions;

use App\Domain\Crm\Models\Customer;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Registers a customer, optionally with their cars in one step (the usual check-in), or edits one.
 * Phone and plates arrive already normalised by the request.
 */
class SaveCustomer
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @param  array{phone: string, name?: ?string, email?: ?string, notes?: ?string, marketing_consent?: bool, vehicles?: list<array<string, mixed>>}  $data
     */
    public function create(User $actor, array $data): Customer
    {
        return DB::transaction(function () use ($actor, $data): Customer {
            $customer = new Customer($data);
            $customer->setMarketingConsent((bool) ($data['marketing_consent'] ?? false));
            $customer->save();

            foreach ($data['vehicles'] ?? [] as $vehicle) {
                $customer->vehicles()->create($vehicle);
            }

            $this->auditTrail->record('customer.created', $customer, $actor, 'Customer registered', [
                'vehicles' => count($data['vehicles'] ?? []),
                'marketing_consent' => $customer->marketing_consent,
            ]);

            return $customer;
        });
    }

    /**
     * @param  array{phone?: string, name?: ?string, email?: ?string, notes?: ?string, marketing_consent?: bool}  $data
     */
    public function update(User $actor, Customer $customer, array $data): Customer
    {
        $customer->fill($data);

        if (array_key_exists('marketing_consent', $data)) {
            $customer->setMarketingConsent((bool) $data['marketing_consent']);
        }

        $changes = array_keys($customer->getDirty());

        if ($changes !== []) {
            $customer->save();

            $this->auditTrail->record('customer.updated', $customer, $actor, 'Customer updated', ['changed' => $changes]);
        }

        return $customer;
    }
}
