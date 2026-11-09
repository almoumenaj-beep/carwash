<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test', function () {
    return view('test');
});

// The web app, built from mobile/ into public/app; its files are served directly, and its own routes live
// after the # in the address.
Route::get('/app', function () {
    abort_unless(is_file(public_path('app/index.html')), 404);

    return response()->file(public_path('app/index.html'), ['Cache-Control' => 'no-cache']);
});
