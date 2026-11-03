import '../../features/auth/domain/me.dart';

/// Permission names used by the app; they mirror the server's catalog.
abstract final class Permissions {
  static const rolesManage = 'roles.manage';
  static const usersManage = 'users.manage';
  static const settingsManage = 'settings.manage';
  static const servicesManage = 'services.manage';
  static const customersView = 'customers.view';
  static const customersCreate = 'customers.create';
  static const customersUpdate = 'customers.update';
  static const customersDelete = 'customers.delete';
  static const ordersView = 'orders.view';
  static const ordersCreate = 'orders.create';
  static const ordersUpdate = 'orders.update';
  static const ordersUpdateStatus = 'orders.update_status';
  static const ordersCancel = 'orders.cancel';
  static const posCheckout = 'pos.checkout';
  static const posDiscount = 'pos.discount';
  static const reportsSales = 'reports.sales';
  static const reportsProfit = 'reports.profit';
  static const expensesView = 'expenses.view';
  static const expensesCreate = 'expenses.create';
  static const expensesApprove = 'expenses.approve';
  static const inventoryView = 'inventory.view';
  static const inventoryAdjust = 'inventory.adjust';
  static const inventoryPurchase = 'inventory.purchase';
  static const equipmentView = 'equipment.view';
  static const equipmentManage = 'equipment.manage';
  static const employeesView = 'employees.view';
  static const employeesManage = 'employees.manage';
  static const payrollView = 'payroll.view';
  static const payrollRun = 'payroll.run';
}

/// Which permissions open each section; holding any one of them is enough.
/// The first matching prefix wins, so a nested rule must come before its parent.
const routePermissions = <String, List<String>>{
  '/queue/new': [Permissions.ordersCreate],
  '/queue': [Permissions.ordersView],
  '/checkout': [Permissions.posCheckout],
  '/shift': [Permissions.posCheckout],
  '/reports': [Permissions.reportsSales],
  '/finance': [Permissions.reportsProfit],
  '/expenses': [Permissions.expensesView],
  '/inventory': [Permissions.inventoryView],
  '/equipment': [Permissions.equipmentView],
  '/staff-affairs': [Permissions.employeesView, Permissions.payrollView],
  '/roles': [Permissions.rolesManage, Permissions.usersManage],
  '/staff': [Permissions.usersManage],
  '/devices': [Permissions.usersManage],
  '/settings': [Permissions.settingsManage],
  '/branches': [Permissions.settingsManage],
  '/catalog': [Permissions.servicesManage],
  '/customers': [Permissions.customersView],
};

/// Whether [me] may open [location] (a path such as `/staff/42`).
bool canOpen(String location, Me me) {
  for (final MapEntry(key: prefix, value: required) in routePermissions.entries) {
    if (location == prefix || location.startsWith('$prefix/')) {
      return required.any(me.can);
    }
  }

  return true;
}
