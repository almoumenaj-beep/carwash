<?php

namespace App\Domain\Staff\Enums;

/**
 * How a staff member's pay terms work out: a monthly salary goes into the month's payroll; a daily-paid
 * staff member is paid ad-hoc wages instead, each recorded as an expense, so the monthly payroll carries
 * no base salary for them (only commission, when set).
 */
enum SalaryType: string
{
    case Monthly = 'monthly';
    case Daily = 'daily';
}
