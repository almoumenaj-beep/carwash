<?php

namespace App\Domain\Appointments\Support;

use App\Domain\Appointments\Enums\AppointmentStatus;
use App\Domain\Appointments\Models\Appointment;
use App\Domain\Platform\Models\Branch;
use Carbon\CarbonImmutable;
use Illuminate\Validation\ValidationException;

/**
 * When cars can be booked at a branch: within its opening hours, not in the past, and with no more cars
 * booked at any moment than it has active bays (one when it has none). Walk-ins are not counted; the
 * reception fits them around the bookings. Times are in the car wash's time zone.
 */
class AppointmentSchedule
{
    /**
     * Minutes between the start times offered.
     */
    public const SLOT_MINUTES = 30;

    public function capacity(Branch $branch): int
    {
        return max(1, $branch->bays()->where('is_active', true)->count());
    }

    /**
     * The most cars booked at the same moment between [$start] and [$end].
     */
    public function busiest(Branch $branch, CarbonImmutable $start, CarbonImmutable $end, ?string $ignoreId = null): int
    {
        $bookings = Appointment::query()
            ->where('branch_id', $branch->id)
            ->where('status', AppointmentStatus::Booked)
            ->where('starts_at', '<', $end->utc())
            ->where('ends_at', '>', $start->utc())
            ->when($ignoreId !== null, fn ($query) => $query->whereKeyNot($ignoreId))
            ->get(['starts_at', 'ends_at']);

        $changes = [];
        foreach ($bookings as $booking) {
            $changes[] = [max($booking->starts_at->getTimestamp(), $start->getTimestamp()), 1];
            $changes[] = [min($booking->ends_at->getTimestamp(), $end->getTimestamp()), -1];
        }
        usort($changes, fn (array $a, array $b) => [$a[0], $a[1]] <=> [$b[0], $b[1]]);

        $now = $busiest = 0;
        foreach ($changes as [, $change]) {
            $now += $change;
            $busiest = max($busiest, $now);
        }

        return $busiest;
    }

    /**
     * @throws ValidationException when the car cannot be booked from [$start] to [$end]
     */
    public function ensureBookable(Branch $branch, CarbonImmutable $start, CarbonImmutable $end, ?string $ignoreId = null): void
    {
        if ($start->lte(CarbonImmutable::now($start->getTimezone()))) {
            throw ValidationException::withMessages(['starts_at' => __('Choose a time that has not passed yet.')]);
        }

        $windows = array_filter([$branch->openingWindow($start), $branch->openingWindow($start->subDay())]);
        $open = array_filter($windows, fn (array $window) => $start->gte($window[0]) && $end->lte($window[1]));
        if ($open === []) {
            throw ValidationException::withMessages(['starts_at' => __('The branch is not open for the whole visit at this time.')]);
        }

        if ($this->busiest($branch, $start, $end, $ignoreId) >= $this->capacity($branch)) {
            throw ValidationException::withMessages(['starts_at' => __('This time is fully booked. Choose another.')]);
        }
    }

    /**
     * The start times on [$date] when a visit of [$minutes] fits, with how many more cars could still be booked then.
     *
     * @return list<array{starts_at: string, time: string, free: int}>
     */
    public function slots(Branch $branch, CarbonImmutable $date, int $minutes, ?string $ignoreId = null): array
    {
        $window = $branch->openingWindow($date);
        if ($window === null) {
            return [];
        }

        $now = CarbonImmutable::now($date->getTimezone());
        $capacity = $this->capacity($branch);
        $slots = [];

        for ($start = $window[0]; $start->addMinutes($minutes)->lte($window[1]); $start = $start->addMinutes(self::SLOT_MINUTES)) {
            if ($start->lte($now)) {
                continue;
            }

            $free = $capacity - $this->busiest($branch, $start, $start->addMinutes($minutes), $ignoreId);
            if ($free > 0) {
                $slots[] = ['starts_at' => $start->format('Y-m-d\TH:i'), 'time' => $start->format('H:i'), 'free' => $free];
            }
        }

        return $slots;
    }
}
