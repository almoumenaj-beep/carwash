<?php

use App\Http\Controllers\CustomerPageController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test', function () {
    return view('test');
});

// The car wash's public customer page: services and prices, offers, and booking a visit.
Route::get('/w/{tenant:slug}', [CustomerPageController::class, 'show'])->name('customer.page');
Route::get('/w/{tenant:slug}/slots', [CustomerPageController::class, 'slots'])->name('customer.slots');
Route::post('/w/{tenant:slug}/bookings', [CustomerPageController::class, 'book'])
    ->middleware('throttle:12,1')
    ->name('customer.book');

// The web app is built from mobile/ into public/app, and its routes live after the # in the address.
Route::redirect('/app', '/app/index.html');
