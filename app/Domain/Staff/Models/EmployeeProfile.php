<?php

namespace App\Domain\Staff\Models;

use App\Domain\Platform\Tenancy\BelongsToTenant;
use App\Domain\Staff\Enums\CommissionType;
use App\Domain\Staff\Enums\SalaryType;
use App\Models\User;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A staff member's pay terms: a monthly salary or daily-paid terms, and commission on the cars they wash.
 * Daily-paid staff are paid ad-hoc wages (each a linked expense), so `monthly_salary` is their base only
 * when the salary type is monthly.
 */
#[Fillable(['user_id', 'monthly_salary', 'salary_type', 'commission_type', 'commission_value'])]
class EmployeeProfile extends Model
{
    use BelongsToTenant, HasUuids;

    /**
     * Mirrors the database defaults so a freshly created profile is complete before it is refreshed.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'monthly_salary' => 0,
        'salary_type' => 'monthly',
        'commission_type' => 'none',
        'commission_value' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'monthly_salary' => 'integer',
            'salary_type' => SalaryType::class,
            'commission_type' => CommissionType::class,
            'commission_value' => 'integer',
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
