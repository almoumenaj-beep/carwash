<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BayController;
use App\Http\Controllers\Api\V1\BranchController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\DeviceStaffController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\MePinController;
use App\Http\Controllers\Api\V1\PermissionController;
use App\Http\Controllers\Api\V1\RoleController;
use App\Http\Controllers\Api\V1\RolePermissionController;
use App\Http\Controllers\Api\V1\ServiceCategoryController;
use App\Http\Controllers\Api\V1\ServiceController;
use App\Http\Controllers\Api\V1\SettingsController;
use App\Http\Controllers\Api\V1\StaffController;
use App\Http\Controllers\Api\V1\UserRoleController;
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

        Route::apiResource('vehicle-sizes', VehicleSizeController::class)->except('show');
        Route::apiResource('service-categories', ServiceCategoryController::class)->except('show');
        Route::apiResource('services', ServiceController::class);

        Route::apiResource('devices', DeviceController::class)->only(['index', 'destroy']);
    });
});
