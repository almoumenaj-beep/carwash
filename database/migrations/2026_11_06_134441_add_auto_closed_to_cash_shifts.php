<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Marks a shift the system closed by itself at the branch's closing time, because the cashier forgot
     * to: its counted cash is only the expected amount, so the drawer still needs a real count.
     */
    public function up(): void
    {
        Schema::table('cash_shifts', function (Blueprint $table) {
            $table->boolean('auto_closed')->default(false)->after('close_note');
        });
    }

    public function down(): void
    {
        Schema::table('cash_shifts', function (Blueprint $table) {
            $table->dropColumn('auto_closed');
        });
    }
};
