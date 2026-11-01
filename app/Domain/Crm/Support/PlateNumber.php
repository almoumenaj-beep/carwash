<?php

namespace App\Domain\Crm\Support;

use Illuminate\Support\Str;

/**
 * One form per plate, so "12 345", "12-345" and "١٢٣٤٥" are the same car: Western digits,
 * upper case, no spaces, dashes or dots.
 */
final class PlateNumber
{
    public static function normalise(string $input): string
    {
        return Str::upper(preg_replace('/[\s\-\.\x{00A0}]/u', '', PhoneNumber::westernDigits($input)));
    }
}
