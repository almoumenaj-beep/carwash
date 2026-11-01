<?php

namespace App\Domain\Crm\Support;

/**
 * Brings the many ways a phone number gets typed to one international form, so a customer
 * is found whatever the cashier typed: "3333 4444", "٣٣٣٣٤٤٤٤", "0097333334444" and
 * "+973 3333-4444" all become "+97333334444".
 */
final class PhoneNumber
{
    public static function normalise(string $input, ?string $defaultDialCode = null): string
    {
        $defaultDialCode ??= config('carwash.default_dial_code');
        $digits = preg_replace('/\D/', '', self::westernDigits($input));
        $typedInternational = str_starts_with(ltrim($input), '+') || str_starts_with($digits, '00');

        if ($typedInternational) {
            return '+'.ltrim(preg_replace('/^00/', '', $digits), '0');
        }

        $dialDigits = ltrim($defaultDialCode, '+');

        // The country code may be typed without "+" (e.g. "97333334444").
        if (str_starts_with($digits, $dialDigits) && strlen($digits) > strlen($dialDigits) + 6) {
            return '+'.$digits;
        }

        return '+'.$dialDigits.ltrim($digits, '0');
    }

    /**
     * Converts Arabic-Indic (٠-٩) and Persian (۰-۹) digits to 0-9.
     */
    public static function westernDigits(string $input): string
    {
        return strtr($input, [
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4', '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
            '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4', '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
        ]);
    }
}
