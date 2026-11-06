<?php

namespace App\Domain\Inventory\Enums;

/**
 * Why a branch's stock changed.
 */
enum StockMovementReason: string
{
    case Purchase = 'purchase';
    case Consumption = 'consumption';
    case Count = 'count';
    case Issue = 'issue';
}
