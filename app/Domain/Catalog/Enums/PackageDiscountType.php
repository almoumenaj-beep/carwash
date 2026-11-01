<?php

namespace App\Domain\Catalog\Enums;

/**
 * How a package's discount is given: a fixed amount off (minor units) or a percentage (basis points).
 */
enum PackageDiscountType: string
{
    case Amount = 'amount';
    case Percent = 'percent';

    /**
     * The discount on $full, the summed price of the package's services; never more than $full.
     */
    public function discountOn(int $full, int $value): int
    {
        $discount = match ($this) {
            self::Amount => $value,
            self::Percent => intdiv(2 * $full * $value + 10000, 20000),
        };

        return min($discount, $full);
    }
}
