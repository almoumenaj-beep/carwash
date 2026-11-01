<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A cashier's shift at a branch's till: opened with the cash float in the drawer, closed with the
     * cash counted. At close the expected cash (float + cash taken) and the variance (counted - expected,
     * negative when short) are stored. Amounts are in minor units (BHD: fils).
     */
    public function up(): void
    {
        Schema::create('cash_shifts', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('branch_id')->constrained();
            $table->foreignUuid('opened_by')->constrained('users');
            $table->unsignedBigInteger('opening_float');
            $table->timestamp('opened_at');
            $table->foreignUuid('closed_by')->nullable()->constrained('users');
            $table->timestamp('closed_at')->nullable();
            $table->unsignedBigInteger('expected_cash')->nullable();
            $table->unsignedBigInteger('counted_cash')->nullable();
            $table->bigInteger('variance')->nullable();
            $table->string('close_note')->nullable();
            $table->timestamps();

            $table->index(['tenant_id', 'branch_id', 'opened_at']);
            $table->index(['opened_by', 'closed_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cash_shifts');
    }
};
