<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Money advanced to a staff member against their pay. It is an expense when given, and is deducted
     * from the next payroll (`payroll_run_id` set once deducted).
     */
    public function up(): void
    {
        Schema::create('salary_advances', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('user_id')->constrained();
            $table->foreignUuid('branch_id')->constrained();
            $table->unsignedBigInteger('amount');
            $table->date('given_on');
            $table->string('note')->nullable();
            $table->foreignUuid('expense_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('payroll_run_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamps();

            $table->index(['tenant_id', 'user_id', 'payroll_run_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('salary_advances');
    }
};
