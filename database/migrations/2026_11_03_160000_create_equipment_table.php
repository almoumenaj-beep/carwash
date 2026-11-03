<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Machines and tools at a branch (pressure washers, vacuums, compressors...). Equipment with a
     * `maintenance_interval_days` is due for periodic maintenance on `next_maintenance_on`, counted from its
     * last periodic maintenance (or purchase, or when it was added).
     */
    public function up(): void
    {
        Schema::create('equipment', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->string('name', 100);
            $table->string('serial_number', 100)->nullable();
            $table->date('purchased_on')->nullable();
            $table->unsignedBigInteger('purchase_cost')->nullable();
            $table->string('status', 20)->default('in_service');
            $table->unsignedSmallInteger('maintenance_interval_days')->nullable();
            $table->date('last_maintained_on')->nullable();
            $table->date('next_maintenance_on')->nullable();
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->index(['tenant_id', 'branch_id']);
            $table->index(['tenant_id', 'next_maintenance_on']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('equipment');
    }
};
