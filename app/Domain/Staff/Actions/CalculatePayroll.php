<?php

namespace App\Domain\Staff\Actions;

use App\Domain\Orders\Enums\OrderStatus;
use App\Domain\Orders\Models\Order;
use App\Domain\Platform\Models\Tenant;
use App\Domain\Staff\Models\EmployeeProfile;
use App\Domain\Staff\Models\PayrollRun;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Works out a month's pay for every active staff member with pay terms: salary and commission on the cars
 * delivered that month (a car's commission split between its washers, a percentage taken of the final amount
 * on its invoice, or of the full price when it was a free wash). Creates the month's draft, or recalculates it; a paid month is final.
 */
class CalculatePayroll
{
    /**
     * @throws ValidationException
     */
    public function handle(User $actor, int $year, int $month): PayrollRun
    {
        return DB::transaction(function () use ($actor, $year, $month): PayrollRun {
            $run = PayrollRun::query()->where('year', $year)->where('month', $month)->lockForUpdate()->first();

            if ($run?->isPaid()) {
                throw ValidationException::withMessages(['payroll' => __('This month has been paid and can no longer change.')]);
            }

            if ($run === null) {
                $run = new PayrollRun;
                $run->forceFill(['year' => $year, 'month' => $month, 'created_by' => $actor->id])->save();
            }

            $this->fill($run, $actor->tenant);

            return $run;
        });
    }

    /**
     * Replaces the run's lines with freshly calculated ones.
     */
    public function fill(PayrollRun $run, Tenant $tenant): void
    {
        [$start, $end] = $run->period($tenant->timezone);

        $profiles = EmployeeProfile::query()->get()->keyBy('user_id');

        $orders = Order::query()
            ->where('status', OrderStatus::Delivered)
            ->where('delivered_at', '>=', $start->utc())
            ->where('delivered_at', '<=', $end->utc())
            ->with(['staff:id', 'invoice:id,order_id,subtotal,total,vat_rate_bps,prices_include_vat,loyalty_reward'])
            ->get(['id', 'subtotal']);

        $cars = [];
        $commission = [];
        foreach ($orders as $order) {
            $washers = $order->staff->count();

            foreach ($order->staff as $washer) {
                $cars[$washer->id] = ($cars[$washer->id] ?? 0) + 1;
                $profile = $profiles->get($washer->id);

                if ($profile !== null) {
                    $commission[$washer->id] = ($commission[$washer->id] ?? 0)
                        + $profile->commission_type->shareOf($profile->commission_value, $order->invoice?->commissionBase() ?? $order->subtotal, $washers);
                }
            }
        }

        $staff = User::query()->where('tenant_id', $tenant->id)->where('is_active', true)->whereKey($profiles->keys())->orderBy('name')->get();

        $run->lines()->delete();
        $total = 0;

        foreach ($staff as $member) {
            $salary = $profiles->get($member->id)?->monthly_salary ?? 0;
            $earned = $commission[$member->id] ?? 0;
            $net = $salary + $earned;

            if ($net === 0) {
                continue;
            }

            $run->lines()->create([
                'user_id' => $member->id,
                'base_salary' => $salary,
                'cars_count' => $cars[$member->id] ?? 0,
                'commission' => $earned,
                'net' => $net,
            ]);
            $total += $net;
        }

        $run->forceFill(['total_net' => $total])->save();
    }
}
