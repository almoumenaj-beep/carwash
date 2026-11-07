<?php

use App\Http\Controllers\Api\V1\AppointmentController;
use App\Http\Controllers\Api\V1\AttendanceController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BayController;
use App\Http\Controllers\Api\V1\BranchController;
use App\Http\Controllers\Api\V1\BranchStaffController;
use App\Http\Controllers\Api\V1\CashShiftController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\DailySalesReportController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\DeviceStaffController;
use App\Http\Controllers\Api\V1\EmployeeController;
use App\Http\Controllers\Api\V1\EquipmentController;
use App\Http\Controllers\Api\V1\ExpenseCategoryController;
use App\Http\Controllers\Api\V1\ExpenseController;
use App\Http\Controllers\Api\V1\FinancialReportController;
use App\Http\Controllers\Api\V1\InventoryController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\MePasswordController;
use App\Http\Controllers\Api\V1\MePinController;
use App\Http\Controllers\Api\V1\MeProfileController;
use App\Http\Controllers\Api\V1\OrderCheckoutController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\OrderStatusController;
use App\Http\Controllers\Api\V1\PayrollController;
use App\Http\Controllers\Api\V1\PermissionController;
use App\Http\Controllers\Api\V1\PurchaseController;
use App\Http\Controllers\Api\V1\RecurringExpenseController;
use App\Http\Controllers\Api\V1\RoleController;
use App\Http\Controllers\Api\V1\RolePermissionController;
use App\Http\Controllers\Api\V1\ServiceCategoryController;
use App\Http\Controllers\Api\V1\ServiceController;
use App\Http\Controllers\Api\V1\ServiceMaterialController;
use App\Http\Controllers\Api\V1\SettingsController;
use App\Http\Controllers\Api\V1\StaffController;
use App\Http\Controllers\Api\V1\SupplierController;
use App\Http\Controllers\Api\V1\UserRoleController;
use App\Http\Controllers\Api\V1\VehicleController;
use App\Http\Controllers\Api\V1\VehicleSizeController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('v1.')->group(function () {
    Route::prefix('auth')->name('auth.')->group(function () {
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:login')->name('login');
        Route::post('pin-login', [AuthController::class, 'pinLogin'])->middleware('throttle:pin-login')->name('pin-login');
        Route::post('device-staff', DeviceStaffController::class)->middleware('throttle:device')->name('device-staff');
        Route::post('logout', [AuthController::class, 'logout'])->middleware('auth:sanctum')->name('logout');
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('me', MeController::class)->name('me');
        Route::put('me/profile', [MeProfileController::class, 'update'])->name('me.profile.update');
        Route::put('me/password', [MePasswordController::class, 'update'])->name('me.password.update');
        Route::put('me/pin', [MePinController::class, 'update'])->name('me.pin.update');

        Route::get('permissions', [PermissionController::class, 'index'])->name('permissions.index');

        Route::apiResource('roles', RoleController::class);
        Route::put('roles/{role}/permissions', [RolePermissionController::class, 'update'])->name('roles.permissions.update');

        Route::apiResource('users', StaffController::class)->except('destroy');
        Route::put('users/{user}/roles', [UserRoleController::class, 'update'])->name('users.roles.update');

        Route::get('settings', [SettingsController::class, 'show'])->name('settings.show');
        Route::patch('settings', [SettingsController::class, 'update'])->name('settings.update');

        Route::apiResource('branches', BranchController::class);
        Route::apiResource('branches.bays', BayController::class)->shallow()->only(['index', 'store', 'update']);
        Route::get('branches/{branch}/staff', BranchStaffController::class)->name('branches.staff.index');

        Route::apiResource('vehicle-sizes', VehicleSizeController::class)->except('show');
        Route::apiResource('service-categories', ServiceCategoryController::class)->except('show');
        Route::apiResource('services', ServiceController::class);

        Route::apiResource('orders', OrderController::class)->only(['index', 'store', 'show', 'update']);
        Route::post('orders/{order}/status', [OrderStatusController::class, 'store'])->name('orders.status.store');
        Route::post('orders/{order}/checkout', [OrderCheckoutController::class, 'store'])->name('orders.checkout.store');

        Route::get('reports/daily-sales', DailySalesReportController::class)->name('reports.daily-sales');
        Route::get('reports/profit-loss', [FinancialReportController::class, 'profitAndLoss'])->name('reports.profit-loss');
        Route::get('reports/cash-flow', [FinancialReportController::class, 'cashFlow'])->name('reports.cash-flow');

        Route::apiResource('expense-categories', ExpenseCategoryController::class)->except('show');
        Route::apiResource('suppliers', SupplierController::class)->only(['index', 'store', 'update']);
        Route::apiResource('recurring-expenses', RecurringExpenseController::class)->except('show');
        Route::apiResource('expenses', ExpenseController::class)->only(['index', 'store', 'destroy']);
        Route::post('expenses/{expense}/pay', [ExpenseController::class, 'pay'])->name('expenses.pay');

        Route::get('inventory/items', [InventoryController::class, 'index'])->name('inventory.items.index');
        Route::post('inventory/items', [InventoryController::class, 'store'])->name('inventory.items.store');
        Route::patch('inventory/items/{item}', [InventoryController::class, 'update'])->name('inventory.items.update');
        Route::post('inventory/counts', [InventoryController::class, 'count'])->name('inventory.counts.store');
        Route::post('inventory/issues', [InventoryController::class, 'issue'])->name('inventory.issues.store');
        Route::post('inventory/issues/{movement}/cancel', [InventoryController::class, 'cancelIssue'])->name('inventory.issues.cancel');
        Route::get('inventory/daily-usage', [InventoryController::class, 'dailyUsage'])->name('inventory.daily-usage');
        Route::get('inventory/movements', [InventoryController::class, 'movements'])->name('inventory.movements.index');
        Route::get('inventory/purchases', [PurchaseController::class, 'index'])->name('inventory.purchases.index');
        Route::post('inventory/purchases', [PurchaseController::class, 'store'])->name('inventory.purchases.store');
        Route::post('inventory/purchases/{purchase}/cancel', [PurchaseController::class, 'cancel'])->name('inventory.purchases.cancel');
        Route::get('appointments', [AppointmentController::class, 'index'])->name('appointments.index');
        Route::get('appointments/slots', [AppointmentController::class, 'slots'])->name('appointments.slots');
        Route::post('appointments', [AppointmentController::class, 'store'])->name('appointments.store');
        Route::patch('appointments/{appointment}', [AppointmentController::class, 'update'])->name('appointments.update');
        Route::post('appointments/{appointment}/cancel', [AppointmentController::class, 'cancel'])->name('appointments.cancel');
        Route::post('appointments/{appointment}/no-show', [AppointmentController::class, 'noShow'])->name('appointments.no-show');
        Route::post('appointments/{appointment}/check-in', [AppointmentController::class, 'checkIn'])->name('appointments.check-in');
        Route::get('equipment', [EquipmentController::class, 'index'])->name('equipment.index');
        Route::post('equipment', [EquipmentController::class, 'store'])->name('equipment.store');
        Route::patch('equipment/{equipment}', [EquipmentController::class, 'update'])->name('equipment.update');
        Route::get('equipment/{equipment}/breakdowns', [EquipmentController::class, 'breakdowns'])->name('equipment.breakdowns.index');
        Route::post('equipment/{equipment}/breakdowns', [EquipmentController::class, 'reportBreakdown'])->name('equipment.breakdowns.store');
        Route::get('equipment/{equipment}/maintenances', [EquipmentController::class, 'maintenances'])->name('equipment.maintenances.index');
        Route::post('equipment/{equipment}/maintenances', [EquipmentController::class, 'maintain'])->name('equipment.maintenances.store');
        Route::post('equipment/{equipment}/maintenances/{maintenance}/cancel', [EquipmentController::class, 'cancelMaintenance'])->name('equipment.maintenances.cancel');
        Route::get('employees', [EmployeeController::class, 'index'])->name('employees.index');
        Route::put('employees/{user}/pay-terms', [EmployeeController::class, 'updateProfile'])->name('employees.pay-terms.update');
        Route::get('attendance', [AttendanceController::class, 'index'])->name('attendance.index');
        Route::get('attendance/summary', [AttendanceController::class, 'summary'])->name('attendance.summary');
        Route::get('attendance/me', [AttendanceController::class, 'me'])->name('attendance.me');
        Route::post('attendance/clock-in', [AttendanceController::class, 'clockIn'])->name('attendance.clock-in');
        Route::post('attendance/clock-out', [AttendanceController::class, 'clockOut'])->name('attendance.clock-out');
        Route::get('payroll-runs', [PayrollController::class, 'index'])->name('payroll-runs.index');
        Route::post('payroll-runs', [PayrollController::class, 'store'])->name('payroll-runs.store');
        Route::post('payroll-runs/{payrollRun}/pay', [PayrollController::class, 'pay'])->name('payroll-runs.pay');
        Route::post('payroll-runs/{payrollRun}/cancel-payment', [PayrollController::class, 'cancelPayment'])->name('payroll-runs.cancel-payment');

        Route::get('services/{service}/materials', [ServiceMaterialController::class, 'show'])->name('services.materials.show');
        Route::put('services/{service}/materials', [ServiceMaterialController::class, 'update'])->name('services.materials.update');

        Route::get('shifts', [CashShiftController::class, 'index'])->name('shifts.index');
        Route::get('shifts/mine', [CashShiftController::class, 'mine'])->name('shifts.mine');
        Route::get('shifts/current', [CashShiftController::class, 'current'])->name('shifts.current');
        Route::post('shifts', [CashShiftController::class, 'store'])->name('shifts.store');
        Route::post('shifts/{shift}/close', [CashShiftController::class, 'close'])->name('shifts.close');
        Route::post('shifts/{shift}/count', [CashShiftController::class, 'count'])->name('shifts.count');

        Route::apiResource('customers', CustomerController::class);
        Route::apiResource('customers.vehicles', VehicleController::class)->shallow()->only(['store', 'update', 'destroy']);

        Route::apiResource('devices', DeviceController::class)->only(['index', 'update', 'destroy']);
    });
});
