<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A purchase recorded by mistake is cancelled, not deleted: it stays listed, its quantities leave the stock
     * and its expense is removed.
     */
    public function up(): void
    {
        Schema::table('purchases', function (Blueprint $table) {
            $table->timestamp('cancelled_at')->nullable()->after('note');
            $table->foreignUuid('cancelled_by')->nullable()->after('cancelled_at')->constrained('users');
        });
    }

    public function down(): void
    {
        Schema::table('purchases', function (Blueprint $table) {
            $table->dropConstrainedForeignId('cancelled_by');
            $table->dropColumn('cancelled_at');
        });
    }
};
