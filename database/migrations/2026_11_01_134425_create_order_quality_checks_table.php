<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * One inspection of a car: who checked it, whether it passed, and whether each service on the
     * order was done properly (`results`: [{item_id, name, passed}], one per order item).
     */
    public function up(): void
    {
        Schema::create('order_quality_checks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('order_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('checked_by')->constrained('users');
            $table->boolean('passed');
            $table->json('results');
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_quality_checks');
    }
};
