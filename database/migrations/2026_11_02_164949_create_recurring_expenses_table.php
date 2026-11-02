<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * An expense that comes back on a schedule (monthly rent, weekly cleaning supplies). On its due
     * date an unpaid expense is recorded and `next_due_on` moves on by its frequency.
     */
    public function up(): void
    {
        Schema::create('recurring_expenses', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->foreignUuid('expense_category_id')->constrained();
            $table->foreignUuid('supplier_id')->nullable()->constrained();
            $table->unsignedBigInteger('amount');
            $table->string('description')->nullable();
            $table->string('frequency', 10);
            $table->date('next_due_on');
            $table->boolean('is_active')->default(true);
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamps();

            $table->index(['is_active', 'next_due_on']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recurring_expenses');
    }
};
