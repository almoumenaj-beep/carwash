<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Memberships: the owner's plans (a price, the services covered, how many washes or null for no limit, how
     * long it lasts, and whether it is for the customer or one car) and what customers bought. A sold membership
     * keeps its own copy of the terms, so changing a plan never changes what a customer already paid for. Selling
     * one issues an invoice with no work order behind it, so an invoice's order is now optional.
     */
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->boolean('memberships_enabled')->default(false);
        });

        Schema::table('invoices', function (Blueprint $table) {
            $table->uuid('order_id')->nullable()->change();
        });

        Schema::create('membership_plans', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->string('name');
            $table->unsignedBigInteger('price');
            $table->unsignedInteger('washes')->nullable();
            $table->unsignedInteger('validity_days');
            $table->string('scope', 20);
            $table->json('service_ids');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['tenant_id', 'is_active']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });

        Schema::create('customer_memberships', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('membership_plan_id')->constrained();
            $table->foreignUuid('customer_id')->constrained();
            $table->foreignUuid('vehicle_id')->nullable()->constrained();
            $table->foreignUuid('invoice_id')->constrained();
            $table->string('name');
            $table->unsignedInteger('washes')->nullable();
            $table->unsignedInteger('washes_used')->default(0);
            $table->json('service_ids');
            $table->timestamp('expires_at');
            $table->foreignUuid('sold_by')->constrained('users');
            $table->timestamp('cancelled_at')->nullable();
            $table->foreignUuid('cancelled_by')->nullable()->constrained('users');
            $table->timestamps();

            $table->index(['customer_id', 'expires_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });

        Schema::table('invoices', function (Blueprint $table) {
            $table->foreignUuid('customer_membership_id')->nullable()->constrained();
        });
    }

    public function down(): void
    {
        Schema::table('invoices', function (Blueprint $table) {
            $table->dropConstrainedForeignId('customer_membership_id');
        });

        Schema::dropIfExists('customer_memberships');
        Schema::dropIfExists('membership_plans');

        Schema::table('invoices', function (Blueprint $table) {
            $table->uuid('order_id')->nullable(false)->change();
        });

        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn('memberships_enabled');
        });
    }
};
