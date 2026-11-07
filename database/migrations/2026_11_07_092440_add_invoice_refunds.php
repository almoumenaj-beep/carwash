<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Money given back for a whole invoice. The invoice stays on record marked as refunded, and an order that was
     * refunded and collected again has a second invoice, so an order may now have more than one.
     */
    public function up(): void
    {
        Schema::table('invoices', function (Blueprint $table) {
            $table->index('order_id');
        });

        Schema::table('invoices', function (Blueprint $table) {
            $table->dropUnique(['order_id']);
            $table->timestamp('refunded_at')->nullable();
        });

        Schema::create('refunds', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('invoice_id')->unique()->constrained();
            $table->foreignUuid('branch_id')->constrained();
            $table->foreignUuid('cash_shift_id')->nullable()->constrained();
            $table->string('method', 20);
            $table->unsignedBigInteger('amount');
            $table->unsignedBigInteger('vat_amount');
            $table->string('reason');
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamps();

            $table->index(['tenant_id', 'branch_id', 'created_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('refunds');

        Schema::table('invoices', function (Blueprint $table) {
            $table->dropColumn('refunded_at');
            $table->unique('order_id');
            $table->dropIndex(['order_id']);
        });
    }
};
