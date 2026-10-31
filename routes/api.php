<?php

use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\PermissionController;
use App\Http\Controllers\Api\V1\RoleController;
use App\Http\Controllers\Api\V1\RolePermissionController;
use App\Http\Controllers\Api\V1\UserRoleController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('v1.')->middleware('auth:sanctum')->group(function () {
    Route::get('me', MeController::class)->name('me');

    Route::get('permissions', [PermissionController::class, 'index'])->name('permissions.index');

    Route::apiResource('roles', RoleController::class);
    Route::put('roles/{role}/permissions', [RolePermissionController::class, 'update'])->name('roles.permissions.update');

    Route::put('users/{user}/roles', [UserRoleController::class, 'update'])->name('users.roles.update');
});
