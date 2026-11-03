<?php

namespace App\Domain\Staff\Enums;

/**
 * How a staff member earns on the cars they wash. A car washed by several staff splits its commission
 * equally between them.
 */
enum CommissionType: string
{
    case None = 'none';
    case PerCar = 'per_car';
    case Percent = 'percent';

    /**
     * One washer's share of a car's commission, in minor units, rounded half up.
     *
     * @param  int  $value  Minor units per car (`per_car`) or basis points of the car's value (`percent`).
     * @param  int  $carValue  What the car's services came to, in minor units.
     * @param  int  $washers  How many staff worked on the car.
     */
    public function shareOf(int $value, int $carValue, int $washers): int
    {
        $washers = max($washers, 1);

        return match ($this) {
            self::None => 0,
            self::PerCar => intdiv(2 * $value + $washers, 2 * $washers),
            self::Percent => intdiv(2 * $carValue * $value + 10000 * $washers, 20000 * $washers),
        };
    }
}
