<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Who later counted the drawer of a shift the system closed. Shifts already closed automatically lose
     * the count they were given, the expected cash, since nobody actually counted them.
     */
    public function up(): void
    {
        Schema::table('cash_shifts', function (Blueprint $table) {
            $table->foreignUuid('counted_by')->nullable()->after('auto_closed')->constrained('users');
            $table->timestamp('counted_at')->nullable()->after('counted_by');
        });

        DB::table('cash_shifts')->where('auto_closed', true)->update([
            'counted_cash' => null,
            'variance' => null,
            'close_note' => null,
        ]);
    }

    public function down(): void
    {
        Schema::table('cash_shifts', function (Blueprint $table) {
            $table->dropConstrainedForeignId('counted_by');
            $table->dropColumn('counted_at');
        });
    }
};
