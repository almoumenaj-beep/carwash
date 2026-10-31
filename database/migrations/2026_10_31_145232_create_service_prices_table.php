<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Price of a service, in the currency's minor unit (BHD: fils), as shown to the customer.
     * A null vehicle_size_id applies to every size and a null branch_id to every branch;
     * the most specific row wins. Uniqueness across nulls is enforced by SaveService.
     */
    public function up(): void
    {
        Schema::create('service_prices', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('service_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('vehicle_size_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignUuid('branch_id')->nullable()->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('price');
            $table->timestamps();

            $table->index(['service_id', 'vehicle_size_id', 'branch_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('service_prices');
    }
};
