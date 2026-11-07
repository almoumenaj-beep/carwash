<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Customers' points, shared by all the car wash's branches and off until the owner turns them on. A point is
     * earned per `points_earn_amount` paid (minor units); `points_redeem_points` points take off
     * `points_redeem_value` (minor units); a balance lapses after `points_expiry_months` without activity, or
     * never when null. `point_transactions` is append-only.
     */
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->boolean('points_enabled')->default(false);
            $table->unsignedInteger('points_earn_amount')->default(1000);
            $table->unsignedInteger('points_redeem_points')->default(100);
            $table->unsignedInteger('points_redeem_value')->default(2000);
            $table->unsignedSmallInteger('points_expiry_months')->nullable();
        });

        Schema::table('customers', function (Blueprint $table) {
            $table->unsignedInteger('points_balance')->default(0);
        });

        Schema::table('invoices', function (Blueprint $table) {
            $table->unsignedInteger('points_redeemed')->default(0);
            $table->unsignedInteger('points_earned')->default(0);
        });

        Schema::create('point_transactions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('customer_id')->constrained();
            $table->foreignUuid('branch_id')->nullable()->constrained();
            $table->string('type', 20);
            $table->integer('points');
            $table->unsignedInteger('balance_after');
            $table->foreignUuid('invoice_id')->nullable()->constrained();
            $table->foreignUuid('created_by')->nullable()->constrained('users');
            $table->timestamps();

            $table->index(['customer_id', 'created_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('point_transactions');

        Schema::table('invoices', function (Blueprint $table) {
            $table->dropColumn(['points_redeemed', 'points_earned']);
        });

        Schema::table('customers', function (Blueprint $table) {
            $table->dropColumn('points_balance');
        });

        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn(['points_enabled', 'points_earn_amount', 'points_redeem_points', 'points_redeem_value', 'points_expiry_months']);
        });
    }
};
