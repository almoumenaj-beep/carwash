<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * The key identifies a default role (e.g. "owner") independently of its editable name; custom roles have none.
     */
    public function up(): void
    {
        Schema::table('roles', function (Blueprint $table) {
            $table->string('key', 50)->nullable()->after('tenant_id');

            $table->unique(['tenant_id', 'key']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('roles', function (Blueprint $table) {
            $table->dropUnique(['tenant_id', 'key']);
            $table->dropColumn('key');
        });
    }
};
