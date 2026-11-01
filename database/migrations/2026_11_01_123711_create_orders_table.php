<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * A work order: one car through the wash. Numbered per branch; the car's plate and size are
     * copied at check-in so later edits to the vehicle do not rewrite history. Amounts are in
     * minor units (BHD: fils) as charged to the customer.
     */
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->unsignedInteger('number');
            $table->foreignUuid('customer_id')->nullable()->constrained();
            $table->foreignUuid('vehicle_id')->nullable()->constrained();
            $table->string('plate_number', 20)->nullable();
            $table->foreignUuid('vehicle_size_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('bay_id')->nullable()->constrained()->nullOnDelete();
            $table->string('status', 20)->default('waiting');
            $table->unsignedBigInteger('subtotal')->default(0);
            $table->unsignedSmallInteger('estimated_minutes')->default(0);
            $table->text('notes')->nullable();
            $table->string('cancel_reason')->nullable();
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('qc_at')->nullable();
            $table->timestamp('ready_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();

            $table->unique(['branch_id', 'number']);
            $table->index(['tenant_id', 'branch_id', 'status']);
            $table->index(['tenant_id', 'branch_id', 'created_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
