<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Money received for an invoice. For cash, `tendered` is what the customer handed over and
     * `change_given` what went back; `amount` is what stays in the till.
     */
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->foreignUuid('invoice_id')->constrained();
            $table->string('method', 20);
            $table->unsignedBigInteger('amount');
            $table->unsignedBigInteger('tendered')->nullable();
            $table->unsignedBigInteger('change_given')->default(0);
            $table->foreignUuid('received_by')->constrained('users');
            $table->timestamp('received_at');
            $table->timestamps();

            $table->index(['tenant_id', 'branch_id', 'received_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
