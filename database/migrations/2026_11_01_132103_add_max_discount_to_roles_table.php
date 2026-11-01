<?php

use App\Domain\Identity\Enums\DefaultRole;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * The largest discount staff holding the role may give at the till, in basis points (1000 = 10%).
     * Existing default roles get their default limit.
     */
    public function up(): void
    {
        $roles = config('permission.table_names.roles');

        Schema::table($roles, function (Blueprint $table) {
            $table->unsignedSmallInteger('max_discount_bps')->default(0)->after('key');
        });

        foreach (DefaultRole::cases() as $defaultRole) {
            if ($defaultRole->maxDiscountBps() > 0) {
                DB::table($roles)->where('key', $defaultRole->value)->update(['max_discount_bps' => $defaultRole->maxDiscountBps()]);
            }
        }
    }

    public function down(): void
    {
        Schema::table(config('permission.table_names.roles'), function (Blueprint $table) {
            $table->dropColumn('max_discount_bps');
        });
    }
};
