<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * The loyalty card: a stamp for each paid visit and a free wash once a customer has enough of them. Off until
     * the owner turns it on. Stamps are shared by all the car wash's branches, like the customer.
     */
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->boolean('loyalty_enabled')->default(false);
            $table->unsignedSmallInteger('loyalty_washes_required')->default(10);
        });

        Schema::table('customers', function (Blueprint $table) {
            $table->unsignedInteger('loyalty_stamps')->default(0);
        });

        Schema::table('invoices', function (Blueprint $table) {
            $table->boolean('loyalty_reward')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('invoices', function (Blueprint $table) {
            $table->dropColumn('loyalty_reward');
        });

        Schema::table('customers', function (Blueprint $table) {
            $table->dropColumn('loyalty_stamps');
        });

        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn(['loyalty_enabled', 'loyalty_washes_required']);
        });
    }
};
