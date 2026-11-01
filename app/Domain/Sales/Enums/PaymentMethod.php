<?php

namespace App\Domain\Sales\Enums;

/**
 * How a payment was made. Cash only for now; card, transfer and wallets come with the payment gateway.
 */
enum PaymentMethod: string
{
    case Cash = 'cash';
}
