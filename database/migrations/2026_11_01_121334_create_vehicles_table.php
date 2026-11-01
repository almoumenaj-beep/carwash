<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * A customer's car. The plate is stored normalised (upper case, no spaces or dashes) and is
     * unique within the car wash; its size picks the price of each service.
     */
    public function up(): void
    {
        Schema::create('vehicles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('customer_id')->constrained()->cascadeOnDelete();
            $table->string('plate_number', 20);
            $table->foreignUuid('vehicle_size_id')->nullable()->constrained()->nullOnDelete();
            $table->string('make', 60)->nullable();
            $table->string('model', 60)->nullable();
            $table->string('color', 40)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['tenant_id', 'plate_number']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};
