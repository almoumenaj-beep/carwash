<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Translation\PotentiallyTranslatedString;

/**
 * One day of a branch's weekly hours: null (closed) or {"opens": "HH:MM", "closes": "HH:MM"}.
 * A closing time earlier than the opening time means the branch closes after midnight.
 */
class OpeningHoursDay implements ValidationRule
{
    /**
     * Run the validation rule.
     *
     * @param  Closure(string, ?string=): PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if ($value === null) {
            return;
        }

        $isTime = fn (mixed $time) => is_string($time) && preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', $time) === 1;

        if (! is_array($value)
            || array_diff(array_keys($value), ['opens', 'closes']) !== []
            || ! $isTime($value['opens'] ?? null)
            || ! $isTime($value['closes'] ?? null)) {
            $fail(__('Each day must be closed or have an opening and closing time (HH:MM).'));

            return;
        }

        if ($value['opens'] === $value['closes']) {
            $fail(__('The opening and closing times must differ.'));
        }
    }
}
