<?php

namespace App\Domain\Sales\Support;

/**
 * VAT on an amount in minor units, rounded half up to the nearest unit (fils).
 *
 * Prices that include VAT have it extracted: 2.200 BHD at 10% holds 0.200 VAT. Prices without
 * VAT have it added on top: 2.000 BHD becomes 2.200.
 */
final class Vat
{
    /**
     * @return array{net: int, vat: int, total: int}
     */
    public static function of(int $amount, int $rateBps, bool $pricesIncludeVat): array
    {
        if ($pricesIncludeVat) {
            $vat = self::roundedDivision($amount * $rateBps, 10000 + $rateBps);

            return ['net' => $amount - $vat, 'vat' => $vat, 'total' => $amount];
        }

        $vat = self::roundedDivision($amount * $rateBps, 10000);

        return ['net' => $amount, 'vat' => $vat, 'total' => $amount + $vat];
    }

    private static function roundedDivision(int $dividend, int $divisor): int
    {
        return intdiv(2 * $dividend + $divisor, 2 * $divisor);
    }
}
