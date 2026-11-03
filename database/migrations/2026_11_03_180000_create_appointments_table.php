<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Cars booked to come in at a branch at a set time. A booking holds what the car will have done
     * (`items`, as at check-in) and the car or the customer's contact; when the car arrives it is
     * checked in and becomes an order (`order_id`). `ends_at` is the start plus the services' time,
     * used to keep bookings within the branch's bays.
     */
    public function up(): void
    {
        Schema::create('appointments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->foreignUuid('customer_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('vehicle_id')->nullable()->constrained()->nullOnDelete();
            $table->string('customer_name')->nullable();
            $table->string('customer_phone', 20)->nullable();
            $table->string('plate_number', 20)->nullable();
            $table->foreignUuid('vehicle_size_id')->nullable()->constrained()->nullOnDelete();
            $table->json('items');
            $table->unsignedBigInteger('estimated_total');
            $table->timestamp('starts_at');
            $table->timestamp('ends_at');
            $table->string('status', 20)->default('booked');
            $table->string('cancel_reason')->nullable();
            $table->foreignUuid('order_id')->nullable()->constrained()->nullOnDelete();
            $table->string('notes', 1000)->nullable();
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamps();

            $table->index(['tenant_id', 'branch_id', 'starts_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appointments');
    }
};
