<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('expenses:generate-recurring')->hourly()->withoutOverlapping(30);
Schedule::command('attendance:close-forgotten')->everyFifteenMinutes()->withoutOverlapping(10);
Schedule::command('cash-shifts:close-forgotten')->everyFifteenMinutes()->withoutOverlapping(10);
Schedule::command('appointments:mark-no-shows')->everyFiveMinutes()->withoutOverlapping(4);
