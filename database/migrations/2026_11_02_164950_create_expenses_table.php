<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Money spent by a branch. Paid expenses carry how they were paid; cash taken from a till's drawer
     * also carries the shift, so the drawer count at close expects less cash. An expense without
     * `paid_at` is still owed (to its supplier, if any). Amounts are in minor units (BHD: fils).
     */
    public function up(): void
    {
        Schema::create('expenses', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->foreignUuid('expense_category_id')->constrained();
            $table->foreignUuid('supplier_id')->nullable()->constrained();
            $table->foreignUuid('recurring_expense_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedBigInteger('amount');
            $table->date('spent_on');
            $table->string('description')->nullable();
            $table->string('payment_method', 20)->nullable();
            $table->foreignUuid('cash_shift_id')->nullable()->constrained();
            $table->timestamp('paid_at')->nullable();
            $table->foreignUuid('paid_by')->nullable()->constrained('users');
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamps();

            $table->index(['tenant_id', 'branch_id', 'spent_on']);
            $table->index(['tenant_id', 'paid_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};
