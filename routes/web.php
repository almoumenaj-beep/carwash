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
// after the # in the address.
Route::get('/app', function () {
    abort_unless(is_file(public_path('app/index.html')), 404);

    return response()->file(public_path('app/index.html'), ['Cache-Control' => 'no-cache']);
});
