<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * The staff working on an order (for task lists now, commissions later).
     */
    public function up(): void
    {
        Schema::create('order_staff', function (Blueprint $table) {
            $table->foreignUuid('order_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained();
            $table->timestamps();

            $table->primary(['order_id', 'user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_staff');
    }
};
