<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Who the car wash buys from or pays (landlord, suppliers, maintenance companies). What is still
     * owed to a supplier is the sum of its unpaid expenses.
     */
    public function up(): void
    {
        Schema::create('suppliers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->string('name', 150);
            $table->string('phone', 20)->nullable();
            $table->text('notes')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['tenant_id', 'name']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('suppliers');
    }
};
