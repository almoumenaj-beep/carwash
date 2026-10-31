<?php

namespace Tests\Feature;

use Illuminate\Support\Arr;
use PHPUnit\Framework\Attributes\TestWith;
use Tests\TestCase;

/**
 * Every English language line has an Arabic counterpart, so no screen falls back to English.
 */
class TranslationCoverageTest extends TestCase
{
    #[TestWith(['validation'])]
    #[TestWith(['auth'])]
    #[TestWith(['permissions'])]
    #[TestWith(['roles'])]
    public function test_arabic_covers_every_english_line(string $group): void
    {
        $english = array_keys(Arr::dot(Arr::except(require lang_path("en/{$group}.php"), ['custom', 'attributes'])));
        $arabic = array_keys(Arr::dot(Arr::except(require lang_path("ar/{$group}.php"), ['custom', 'attributes'])));

        $this->assertSame([], array_values(array_diff($english, $arabic)), "Missing Arabic lines in {$group}.php");
    }
}
