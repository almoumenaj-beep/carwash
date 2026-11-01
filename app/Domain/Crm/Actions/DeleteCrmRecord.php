<?php

namespace App\Domain\Crm\Actions;

use App\Domain\Crm\Models\Customer;
use App\Domain\Crm\Models\Vehicle;
use App\Domain\Platform\Audit\AuditTrail;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Deletes a customer (with their cars) or a single car when nothing depends on it yet;
 * once orders exist, history is kept and these deletions are refused.
 */
class DeleteCrmRecord
{
    public function __construct(private AuditTrail $auditTrail) {}

    /**
     * @throws ValidationException
     */
    public function handle(User $actor, Customer|Vehicle $record): void
    {
        $isCustomer = $record instanceof Customer;

        if ($record->isInUse()) {
            throw ValidationException::withMessages([
                $isCustomer ? 'customer' : 'vehicle' => $isCustomer
                    ? __('This customer has visits on record and cannot be deleted.')
                    : __('This vehicle has visits on record and cannot be deleted.'),
            ]);
        }

        DB::transaction(function () use ($actor, $record, $isCustomer): void {
            $this->auditTrail->record($isCustomer ? 'customer.deleted' : 'vehicle.deleted', $record, $actor, 'Record deleted', [
                'label' => $isCustomer ? $record->phone : $record->plate_number,
            ]);

            $record->delete();
        });
    }
}
