<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * How much of each material a branch holds, in thousandths of the unit. It may go below zero when
     * washes use more than was recorded, which a stock count then corrects.
     */
    public function up(): void
    {
        Schema::create('inventory_stock', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('inventory_item_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('branch_id')->constrained();
            $table->bigInteger('quantity_milli')->default(0);
            $table->timestamps();

            $table->unique(['inventory_item_id', 'branch_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_stock');
    }
};
