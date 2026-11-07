<?php

namespace App\Domain\Sales\Enums;

/**
 * What moved a customer's points: earned on a paid invoice, spent on a discount, or lost after long inactivity.
 */
enum PointTransactionType: string
{
    case Earned = 'earned';
    case Redeemed = 'redeemed';
    case Expired = 'expired';
}
