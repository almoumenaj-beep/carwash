<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Pay terms gain a salary type (`monthly` or `daily`: daily-paid staff are paid ad-hoc wages recorded
     * as expenses linked to them through expenses.employee_id). The attendance system (clock in/out logs
     * and the per-role clock-in requirement) is dropped.
     */
    public function up(): void
    {
        Schema::table('employee_profiles', function (Blueprint $table) {
            $table->string('salary_type', 10)->default('monthly')->after('monthly_salary');
        });

        Schema::table('expenses', function (Blueprint $table) {
            $table->foreignUuid('employee_id')->nullable()->after('supplier_id')->constrained('users')->nullOnDelete();
        });

        Schema::dropIfExists('attendance_logs');

        $roles = config('permission.table_names.roles');

        if (Schema::hasColumn($roles, 'requires_attendance')) {
            Schema::table($roles, function (Blueprint $table) {
                $table->dropColumn('requires_attendance');
            });
        }
    }

    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            $table->dropConstrainedForeignId('employee_id');
        });

        Schema::table('employee_profiles', function (Blueprint $table) {
            $table->dropColumn('salary_type');
        });
    }
};
