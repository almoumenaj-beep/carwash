<?php

namespace App\Domain\Identity\Enums;

/**
 * Roles copied into every new tenant. The value is stored in roles.key so a default role stays
 * identifiable after the owner renames it or edits its permissions.
 */
enum DefaultRole: string
{
    case Owner = 'owner';
    case BranchManager = 'branch_manager';
    case Cashier = 'cashier';
    case Washer = 'washer';
    case Accountant = 'accountant';
    case InventoryKeeper = 'inventory_keeper';
    case Receptionist = 'receptionist';

    public function displayName(): string
    {
        return match ($this) {
            self::Owner => 'Owner',
            self::BranchManager => 'Branch Manager',
            self::Cashier => 'Cashier',
            self::Washer => 'Washer',
            self::Accountant => 'Accountant',
            self::InventoryKeeper => 'Inventory Keeper',
            self::Receptionist => 'Receptionist',
        };
    }

    /**
     * The permissions the role starts with. The owner is granted everything by a gate check instead,
     * so it keeps full access when the catalog grows.
     *
     * @return list<Permission>
     */
    public function permissions(): array
    {
        return match ($this) {
            self::Owner => [],
            self::BranchManager => [
                Permission::OrdersView, Permission::OrdersCreate, Permission::OrdersUpdate,
                Permission::OrdersUpdateStatus, Permission::OrdersCancel, Permission::OrdersRefund,
                Permission::PosCheckout, Permission::PosDiscount, Permission::PosPriceOverride, Permission::PosCloseShift,
                Permission::AppointmentsManage,
                Permission::CustomersView, Permission::CustomersCreate, Permission::CustomersUpdate,
                Permission::InventoryView, Permission::InventoryAdjust, Permission::InventoryPurchase,
                Permission::ExpensesView, Permission::ExpensesCreate,
                Permission::EmployeesView, Permission::EmployeesManage, Permission::UsersManage,
                Permission::ReportsSales,
                Permission::CrmSendMessages,
            ],
            self::Cashier => [
                Permission::OrdersView, Permission::OrdersCreate, Permission::OrdersUpdate, Permission::OrdersUpdateStatus,
                Permission::PosCheckout, Permission::PosDiscount, Permission::PosCloseShift,
                Permission::CustomersView, Permission::CustomersCreate, Permission::CustomersUpdate,
            ],
            self::Washer => [
                Permission::OrdersView, Permission::OrdersUpdateStatus,
            ],
            self::Accountant => [
                Permission::OrdersView,
                Permission::CustomersView,
                Permission::InventoryView,
                Permission::ExpensesView, Permission::ExpensesCreate, Permission::ExpensesApprove,
                Permission::EmployeesView, Permission::PayrollView, Permission::PayrollRun,
                Permission::ReportsSales, Permission::ReportsProfit, Permission::ReportsExport,
            ],
            self::InventoryKeeper => [
                Permission::InventoryView, Permission::InventoryAdjust, Permission::InventoryPurchase,
            ],
            self::Receptionist => [
                Permission::OrdersView, Permission::OrdersCreate,
                Permission::AppointmentsManage,
                Permission::CustomersView, Permission::CustomersCreate, Permission::CustomersUpdate,
            ],
        };
    }
}
