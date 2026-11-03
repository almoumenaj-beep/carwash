<?php

namespace App\Domain\Equipment\Enums;

/**
 * Whether a piece of equipment can be used. Retired equipment is kept for its history but no longer
 * falls due for maintenance.
 */
enum EquipmentStatus: string
{
    case InService = 'in_service';
    case OutOfService = 'out_of_service';
    case Retired = 'retired';
}
