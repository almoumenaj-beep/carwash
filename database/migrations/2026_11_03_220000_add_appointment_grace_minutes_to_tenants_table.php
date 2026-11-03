<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * How long after its time a booked car may still come before the booking is marked as a no-show on its
     * own; null leaves late bookings for the staff to settle.
     */
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->unsignedSmallInteger('appointment_grace_minutes')->nullable()->default(30)->after('vat_number');
        });
    }

    public function down(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn('appointment_grace_minutes');
        });
    }
};
