<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * The VAT rate is stored in basis points (1000 = 10.00%) to avoid fractional numbers.
     * Defaults match Bahrain: 10% VAT included in displayed prices.
     */
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->unsignedSmallInteger('vat_rate_bps')->default(1000)->after('timezone');
            $table->boolean('prices_include_vat')->default(true)->after('vat_rate_bps');
            $table->string('vat_number', 30)->nullable()->after('prices_include_vat');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn(['vat_rate_bps', 'prices_include_vat', 'vat_number']);
        });
    }
};
