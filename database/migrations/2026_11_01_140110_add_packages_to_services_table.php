<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A package is a service (is_package) bundling other services, listed in display order in
     * `service_package_items`. Its price is theirs for the car's size and branch less its discount:
     * an amount in minor units, or a percentage in basis points (1500 = 15%).
     */
    public function up(): void
    {
        Schema::table('services', function (Blueprint $table) {
            $table->boolean('is_package')->default(false)->after('is_addon');
            $table->string('package_discount_type', 10)->nullable()->after('is_package');
            $table->unsignedInteger('package_discount_value')->default(0)->after('package_discount_type');
        });

        Schema::create('service_package_items', function (Blueprint $table) {
            $table->foreignUuid('package_id')->constrained('services')->cascadeOnDelete();
            $table->foreignUuid('service_id')->constrained('services');
            $table->unsignedSmallInteger('sort_order')->default(0);

            $table->primary(['package_id', 'service_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_package_items');

        Schema::table('services', function (Blueprint $table) {
            $table->dropColumn(['is_package', 'package_discount_type', 'package_discount_value']);
        });
    }
};
