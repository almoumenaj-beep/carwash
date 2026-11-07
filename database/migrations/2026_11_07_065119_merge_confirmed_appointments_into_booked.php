<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * The confirmed status is gone: it changed nothing, so those bookings are simply booked.
     */
    public function up(): void
    {
        DB::table('appointments')->where('status', 'confirmed')->update(['status' => 'booked']);
    }

    public function down(): void
    {
        // Which bookings had been confirmed is not kept.
    }
};
