<?php

namespace App\Domain\Platform\Enums;

enum TenantStatus: string
{
    case Active = 'active';
    case Suspended = 'suspended';
}
