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

// The web app, built from mobile/ into public/app; its files are served directly, and its own routes live
// after the # in the address. Redirect to the trailing slash: the app's asset paths are relative, and
// without the slash the browser would resolve them one directory up.
Route::redirect('/app', '/app/');
