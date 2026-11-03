<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Salary advances are dropped at the owner's request: payroll is salary plus commission only. Expenses
     * already recorded for advances stay as ordinary expenses.
     */
    public function up(): void
    {
        Schema::dropIfExists('salary_advances');

        Schema::table('payroll_lines', function (Blueprint $table) {
            $table->dropColumn('advances');
        });
    }

    public function down(): void
    {
        Schema::table('payroll_lines', function (Blueprint $table) {
            $table->unsignedBigInteger('advances')->default(0)->after('commission');
        });

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
};
