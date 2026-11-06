<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Translation\PotentiallyTranslatedString;

/**
 * A PIN that is not one of the first guesses: all the same digit (1111) or consecutive digits, up or down
 * (1234, 4321).
 */
class SafePin implements ValidationRule
{
    /**
     * Run the validation rule.
     *
     * @param  Closure(string, ?string=): PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        $digits = is_scalar($value) ? str_split((string) $value) : [];

        if (count($digits) < 2) {
            return;
        }

        $steps = [];
        for ($i = 1; $i < count($digits); $i++) {
            $steps[] = (int) $digits[$i] - (int) $digits[$i - 1];
        }

        $steps = array_unique($steps);

        if (count($steps) === 1 && in_array(reset($steps), [0, 1, -1], true)) {
            $fail(__('This PIN is too easy to guess. Choose another.'));
        }
    }
}
