<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A month's pay: drafted (and recalculated) until paid, then fixed. Each line is one staff member's
     * salary, commission on the cars delivered that month, advances deducted, and what is paid (`net`).
     * Paying records it as an expense. Amounts are in minor units.
     */
    public function up(): void
    {
        Schema::create('payroll_runs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->unsignedSmallInteger('year');
            $table->unsignedTinyInteger('month');
            $table->string('status', 10)->default('draft');
            $table->bigInteger('total_net')->default(0);
            $table->foreignUuid('expense_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('paid_at')->nullable();
            $table->foreignUuid('paid_by')->nullable()->constrained('users');
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamps();

            $table->unique(['tenant_id', 'year', 'month']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });

        Schema::create('payroll_lines', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('payroll_run_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained();
            $table->unsignedBigInteger('base_salary');
            $table->unsignedInteger('cars_count');
            $table->unsignedBigInteger('commission');
            $table->unsignedBigInteger('advances');
            $table->bigInteger('net');
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payroll_lines');
        Schema::dropIfExists('payroll_runs');
    }
};
