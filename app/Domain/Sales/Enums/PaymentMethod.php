<?php

namespace App\Domain\Sales\Enums;

/**
 * How a payment was made. Card and Benefit are recorded by hand once the cashier has confirmed the
 * money arrived; no payment gateway is connected yet. Only cash goes in the drawer.
 */
enum PaymentMethod: string
{
    case Cash = 'cash';
    case Card = 'card';
    case Benefit = 'benefit';
}
