<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Materials the car wash keeps in stock (soap, wax, towels...). Quantities throughout inventory are
     * integers in thousandths of the unit (`*_milli`: 50 = 0.050 litre); `unit_cost` is the last
     * purchase price per unit in minor units, and `min_stock_milli` the level that raises an alert.
     */
    public function up(): void
    {
        Schema::create('inventory_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->string('name', 100);
            $table->string('unit', 20);
            $table->unsignedBigInteger('unit_cost')->default(0);
            $table->unsignedBigInteger('min_stock_milli')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['tenant_id', 'name']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_items');
    }
};
