<?php

namespace Tests\Unit;

use App\Domain\Crm\Support\PhoneNumber;
use App\Domain\Crm\Support\PlateNumber;
use PHPUnit\Framework\Attributes\TestWith;
use PHPUnit\Framework\TestCase;

class IdentifierNormalisationTest extends TestCase
{
    #[TestWith(['3333 4444'])]
    #[TestWith(['33334444'])]
    #[TestWith(['٣٣٣٣٤٤٤٤'])]
    #[TestWith(['033334444'])]
    #[TestWith(['+973 3333-4444'])]
    #[TestWith(['00973 3333 4444'])]
    #[TestWith(['97333334444'])]
    #[TestWith(['(+973) 3333 4444'])]
    public function test_bahraini_numbers_typed_any_way_become_one_international_form(string $typed): void
    {
        $this->assertSame('+97333334444', PhoneNumber::normalise($typed, '+973'));
    }

    public function test_a_local_number_that_starts_like_the_dial_code_keeps_its_digits(): void
    {
        $this->assertSame('+97397312345', PhoneNumber::normalise('97312345', '+973'));
    }

    public function test_foreign_numbers_keep_their_own_country_code(): void
    {
        $this->assertSame('+966501234567', PhoneNumber::normalise('+966 50 123 4567', '+973'));
        $this->assertSame('+966501234567', PhoneNumber::normalise('00966501234567', '+973'));
    }

    #[TestWith(['12 345', '12345'])]
    #[TestWith(['12-345', '12345'])]
    #[TestWith(['١٢٣٤٥', '12345'])]
    #[TestWith(['ab 1234', 'AB1234'])]
    #[TestWith(['  77.001 ', '77001'])]
    public function test_plates_are_compared_in_one_form(string $typed, string $stored): void
    {
        $this->assertSame($stored, PlateNumber::normalise($typed));
    }
}
