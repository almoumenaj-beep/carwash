<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A tax invoice, issued when an order is paid and never changed afterwards (a correction is a
     * refund). Numbered per branch. `subtotal` is the sum of the lines, `total` what the customer
     * pays after the discount; the VAT rate and whether prices include it are copied from the
     * settings at issue time. Amounts are in minor units (BHD: fils).
     */
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->unsignedInteger('number');
            $table->foreignUuid('order_id')->unique()->constrained();
            $table->foreignUuid('customer_id')->nullable()->constrained();
            $table->unsignedBigInteger('subtotal');
            $table->unsignedBigInteger('discount_total')->default(0);
            $table->string('discount_reason')->nullable();
            $table->unsignedBigInteger('total');
            $table->unsignedSmallInteger('vat_rate_bps');
            $table->boolean('prices_include_vat');
            $table->unsignedBigInteger('vat_amount');
            $table->foreignUuid('issued_by')->constrained('users');
            $table->timestamp('issued_at');
            $table->timestamps();

            $table->unique(['branch_id', 'number']);
            $table->index(['tenant_id', 'branch_id', 'issued_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoices');
    }
};
