<?php

namespace App\Domain\Expenses\Enums;

/**
 * How an expense was paid. Cash from a till's drawer is taken during the payer's open shift there,
 * so the drawer count at close expects that much less.
 */
enum ExpensePaymentMethod: string
{
    case CashDrawer = 'cash_drawer';
    case Cash = 'cash';
    case BankTransfer = 'bank_transfer';
    case Card = 'card';
}
