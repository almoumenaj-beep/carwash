<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Bookings made by customers themselves from the public page have no staff member behind them.
     */
    public function up(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            $table->uuid('created_by')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            $table->uuid('created_by')->nullable(false)->change();
        });
    }
};
