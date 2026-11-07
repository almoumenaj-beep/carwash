<?php

namespace App\Domain\Memberships\Enums;

/**
 * Who a membership is for: any car of the customer, or one car only.
 */
enum MembershipScope: string
{
    case Customer = 'customer';
    case Vehicle = 'vehicle';
}
