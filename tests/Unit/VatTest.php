<?php

namespace Tests\Unit;

use App\Domain\Sales\Support\Vat;
use PHPUnit\Framework\TestCase;

class VatTest extends TestCase
{
    public function test_vat_is_extracted_from_prices_that_include_it(): void
    {
        $this->assertSame(['net' => 2000, 'vat' => 200, 'total' => 2200], Vat::of(2200, 1000, true));
        $this->assertSame(['net' => 2273, 'vat' => 227, 'total' => 2500], Vat::of(2500, 1000, true));
    }

    public function test_vat_is_added_to_prices_without_it(): void
    {
        $this->assertSame(['net' => 2000, 'vat' => 200, 'total' => 2200], Vat::of(2000, 1000, false));
        $this->assertSame(['net' => 1005, 'vat' => 101, 'total' => 1106], Vat::of(1005, 1000, false));
    }

    public function test_no_vat_at_a_zero_rate(): void
    {
        $this->assertSame(['net' => 2500, 'vat' => 0, 'total' => 2500], Vat::of(2500, 0, true));
        $this->assertSame(['net' => 0, 'vat' => 0, 'total' => 0], Vat::of(0, 1000, true));
    }
}
