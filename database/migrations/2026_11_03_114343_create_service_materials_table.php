<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * What one sale of a service uses up (its bill of materials), in thousandths of each material's unit.
     */
    public function up(): void
    {
        Schema::create('service_materials', function (Blueprint $table) {
            $table->foreignUuid('service_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('inventory_item_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('quantity_milli');

            $table->primary(['service_id', 'inventory_item_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_materials');
    }
};
