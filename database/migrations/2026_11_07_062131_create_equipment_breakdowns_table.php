<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Each time a piece of equipment was reported broken, and why.
     */
    public function up(): void
    {
        Schema::create('equipment_breakdowns', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('equipment_id')->constrained('equipment');
            $table->string('reason');
            $table->foreignUuid('reported_by')->constrained('users');
            $table->timestamp('reported_at');
            $table->timestamps();

            $table->index(['equipment_id', 'reported_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('equipment_breakdowns');
    }
};
