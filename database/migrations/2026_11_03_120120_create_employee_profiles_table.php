<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Pay terms of a staff member: a monthly salary and a commission on the cars they wash, either an
     * amount per car (`per_car`, minor units) or a share of the cars' value (`percent`, basis points).
     */
    public function up(): void
    {
        Schema::create('employee_profiles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('monthly_salary')->default(0);
            $table->string('commission_type', 10)->default('none');
            $table->unsignedInteger('commission_value')->default(0);
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_profiles');
    }
};
