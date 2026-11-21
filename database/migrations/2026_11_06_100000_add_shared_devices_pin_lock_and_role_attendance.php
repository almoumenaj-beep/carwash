<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Switching users by PIN only works on a device the car wash marked as shared (optionally for one
     * branch), and wrong PINs lock it for a while.
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
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['pin_failed_attempts', 'pin_locked_until']);
        });

        Schema::table('devices', function (Blueprint $table) {
            $table->dropConstrainedForeignId('shared_branch_id');
            $table->dropColumn('is_shared');
        });
    }
};
