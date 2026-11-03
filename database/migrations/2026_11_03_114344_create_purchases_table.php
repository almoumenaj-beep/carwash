<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Materials bought and received at a branch, with their lines. Each purchase is also recorded as an
     * expense (paid, or owed to the supplier), so spending and payables stay in one place.
     */
    public function up(): void
    {
        Schema::create('purchases', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->foreignUuid('supplier_id')->nullable()->constrained();
            $table->foreignUuid('expense_id')->nullable()->constrained()->nullOnDelete();
            $table->date('purchased_on');
            $table->unsignedBigInteger('total');
            $table->string('note')->nullable();
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamps();

            $table->index(['tenant_id', 'branch_id', 'purchased_on']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });

        Schema::create('purchase_lines', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('purchase_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('inventory_item_id')->constrained();
            $table->unsignedBigInteger('quantity_milli');
            $table->unsignedBigInteger('unit_cost');
            $table->unsignedBigInteger('line_total');
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('purchase_lines');
        Schema::dropIfExists('purchases');
    }
};
