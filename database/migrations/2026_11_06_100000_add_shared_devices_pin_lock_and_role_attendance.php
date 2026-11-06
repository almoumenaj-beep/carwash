<?php

use App\Domain\Identity\Enums\DefaultRole;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Switching users by PIN only works on a device the car wash marked as shared (optionally for one
     * branch), and wrong PINs lock it for a while. Each role says whether its staff must clock in before
     * working; existing default roles get their default.
     */
    public function up(): void
    {
        Schema::table('devices', function (Blueprint $table) {
            $table->boolean('is_shared')->default(false)->after('platform');
            $table->foreignUuid('shared_branch_id')->nullable()->after('is_shared')->constrained('branches')->nullOnDelete();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->unsignedTinyInteger('pin_failed_attempts')->default(0)->after('pin_hash');
            $table->timestamp('pin_locked_until')->nullable()->after('pin_failed_attempts');
        });

        $roles = config('permission.table_names.roles');

        Schema::table($roles, function (Blueprint $table) {
            $table->boolean('requires_attendance')->default(true)->after('max_discount_bps');
        });

        foreach (DefaultRole::cases() as $defaultRole) {
            if (! $defaultRole->requiresAttendance()) {
                DB::table($roles)->where('key', $defaultRole->value)->update(['requires_attendance' => false]);
            }
        }
    }

    public function down(): void
    {
        Schema::table(config('permission.table_names.roles'), function (Blueprint $table) {
            $table->dropColumn('requires_attendance');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['pin_failed_attempts', 'pin_locked_until']);
        });

        Schema::table('devices', function (Blueprint $table) {
            $table->dropConstrainedForeignId('shared_branch_id');
            $table->dropColumn('is_shared');
        });
    }
};
