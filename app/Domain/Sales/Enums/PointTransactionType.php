<?php

namespace App\Domain\Sales\Enums;

/**
 * What moved a customer's points: earned on a paid invoice, spent on a discount, lost after long inactivity, or
 * put right when an invoice was refunded.
 */
enum PointTransactionType: string
{
    case Earned = 'earned';
    case Redeemed = 'redeemed';
    case Expired = 'expired';
    case Refund = 'refund';
}
