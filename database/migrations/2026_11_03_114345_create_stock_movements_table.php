<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Every change to a branch's stock, append-only: purchases in, washes using materials up, and stock
     * counts correcting the difference. `change_milli` is signed; `order_id` / `purchase_id` say why.
     */
    public function up(): void
    {
        Schema::create('stock_movements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->foreignUuid('inventory_item_id')->constrained()->cascadeOnDelete();
            $table->string('reason', 20);
            $table->bigInteger('change_milli');
            $table->bigInteger('balance_milli');
            $table->foreignUuid('order_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('purchase_id')->nullable()->constrained()->nullOnDelete();
            $table->string('note')->nullable();
            $table->foreignUuid('user_id')->nullable()->constrained();
            $table->timestamp('created_at', 6)->useCurrent();

            $table->index(['tenant_id', 'branch_id', 'inventory_item_id', 'created_at'], 'stock_movements_history_index');
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_movements');
    }
};
