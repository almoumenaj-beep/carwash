<?php

namespace App\Domain\Identity\Enums;

use Illuminate\Support\Str;

/**
 * The permission catalog. Permissions are defined in code as "module.action" and synced to the
 * database by PermissionSeeder; tenants combine them into roles but never create new ones.
 */
enum Permission: string
{
    case OrdersView = 'orders.view';
    case OrdersCreate = 'orders.create';
    case OrdersUpdate = 'orders.update';
    case OrdersUpdateStatus = 'orders.update_status';
    case OrdersCancel = 'orders.cancel';
    case OrdersRefund = 'orders.refund';

    case PosCheckout = 'pos.checkout';
    case PosDiscount = 'pos.discount';
    case PosPriceOverride = 'pos.price_override';
    case PosCloseShift = 'pos.close_shift';

    case AppointmentsManage = 'appointments.manage';

    case CustomersView = 'customers.view';
    case CustomersCreate = 'customers.create';
    case CustomersUpdate = 'customers.update';
    case CustomersDelete = 'customers.delete';
    case CustomersExport = 'customers.export';

    case ServicesManage = 'services.manage';

    case InventoryView = 'inventory.view';
    case InventoryAdjust = 'inventory.adjust';
    case InventoryPurchase = 'inventory.purchase';

    case ExpensesView = 'expenses.view';
    case ExpensesCreate = 'expenses.create';
    case ExpensesApprove = 'expenses.approve';

    case EmployeesView = 'employees.view';
    case EmployeesManage = 'employees.manage';

    case PayrollView = 'payroll.view';
    case PayrollRun = 'payroll.run';

    case ReportsSales = 'reports.sales';
    case ReportsProfit = 'reports.profit';
    case ReportsExport = 'reports.export';

    case CrmSendMessages = 'crm.send_messages';
    case CrmManageCampaigns = 'crm.manage_campaigns';

    case SettingsManage = 'settings.manage';
    case RolesManage = 'roles.manage';
    case UsersManage = 'users.manage';

    /**
     * The module this permission belongs to, used to group the catalog.
     */
    public function module(): string
    {
        return Str::before($this->value, '.');
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
