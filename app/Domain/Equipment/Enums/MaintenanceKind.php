<?php

namespace App\Domain\Equipment\Enums;

/**
 * Periodic maintenance restarts the equipment's maintenance schedule; a repair puts broken equipment
 * back in service.
 */
enum MaintenanceKind: string
{
    case Periodic = 'periodic';
    case Repair = 'repair';
}
