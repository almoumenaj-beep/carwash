<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A package sold on an order is one priced item (is_package) with the services it includes as
     * unpriced child items (parent_id), so each of them is inspected and, later, counted per service.
     */
    public function up(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            $table->boolean('is_package')->default(false)->after('is_addon');
            $table->foreignUuid('parent_id')->nullable()->after('order_id')->constrained('order_items')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            $table->dropConstrainedForeignId('parent_id');
            $table->dropColumn('is_package');
        });
    }
};
