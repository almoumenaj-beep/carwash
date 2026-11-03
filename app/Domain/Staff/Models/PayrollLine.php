<?php

namespace App\Domain\Staff\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * One staff member's pay for a month: salary + commission − advances = net.
 */
#[Fillable(['user_id', 'base_salary', 'cars_count', 'commission', 'advances', 'net'])]
class PayrollLine extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'base_salary' => 'integer',
            'cars_count' => 'integer',
            'commission' => 'integer',
            'advances' => 'integer',
            'net' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
