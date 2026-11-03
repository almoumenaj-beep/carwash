<?php

namespace App\Domain\Inventory\Support;

/**
 * Stock quantities are kept as integers in thousandths of the unit (0.050 litre = 50), so sums never drift.
 * The API speaks plain decimal numbers with up to three places.
 */
final class Quantity
{
    public static function toMilli(int|float|string $quantity): int
    {
        return (int) round(((float) $quantity) * 1000);
    }

    public static function fromMilli(int $milli): float
    {
        return $milli / 1000;
    }
}
