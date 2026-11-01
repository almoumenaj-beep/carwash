<?php

namespace App\Domain\Orders\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\WithoutTimestamps;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * One inspection of a car against the checklist; `results` keeps each item's name as it was.
 */
#[Fillable(['checked_by', 'passed', 'results', 'created_at'])]
#[WithoutTimestamps]
class OrderQualityCheck extends Model
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
            'passed' => 'boolean',
            'results' => 'array',
            'created_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function checker(): BelongsTo
    {
        return $this->belongsTo(User::class, 'checked_by');
    }
}
