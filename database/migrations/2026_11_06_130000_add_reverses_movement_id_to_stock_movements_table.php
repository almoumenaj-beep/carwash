<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Stock movements are never edited: cancelling an issue writes a movement putting the quantity back, which
     * points to the issue it reverses. Unique, so an issue can only be cancelled once.
     */
    public function up(): void
    {
        Schema::table('stock_movements', function (Blueprint $table) {
            $table->foreignUuid('reverses_movement_id')->nullable()->unique()->after('issued_to')->constrained('stock_movements');
        });
    }

    public function down(): void
    {
        Schema::table('stock_movements', function (Blueprint $table) {
            $table->dropConstrainedForeignId('reverses_movement_id');
        });
    }
};
