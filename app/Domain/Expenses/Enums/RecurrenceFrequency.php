<?php

namespace App\Domain\Expenses\Enums;

use Carbon\CarbonImmutable;

/**
 * How often a recurring expense falls due.
 */
enum RecurrenceFrequency: string
{
    case Weekly = 'weekly';
    case Monthly = 'monthly';
    case Yearly = 'yearly';

    /**
     * The due date after $date. Monthly and yearly dates keep their day where the month allows
     * (31 January is followed by 28 or 29 February).
     */
    public function after(CarbonImmutable $date): CarbonImmutable
    {
        return match ($this) {
            self::Weekly => $date->addWeek(),
            self::Monthly => $date->addMonthNoOverflow(),
            self::Yearly => $date->addYearNoOverflow(),
        };
    }
}
