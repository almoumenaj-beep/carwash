<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('expenses:generate-recurring')->hourly()->withoutOverlapping();
Schedule::command('attendance:close-forgotten')->everyFifteenMinutes()->withoutOverlapping();
Schedule::command('appointments:mark-no-shows')->everyFiveMinutes()->withoutOverlapping();
