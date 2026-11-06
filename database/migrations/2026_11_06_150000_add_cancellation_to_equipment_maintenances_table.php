<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Maintenance recorded by mistake is cancelled, not deleted. `put_back_in_service` remembers that a repair
     * brought broken equipment back, so cancelling it can undo that.
     */
    public function up(): void
    {
        Schema::table('equipment_maintenances', function (Blueprint $table) {
            $table->boolean('put_back_in_service')->default(false)->after('expense_id');
            $table->timestamp('cancelled_at')->nullable()->after('put_back_in_service');
            $table->foreignUuid('cancelled_by')->nullable()->after('cancelled_at')->constrained('users');
        });
    }

    public function down(): void
    {
        Schema::table('equipment_maintenances', function (Blueprint $table) {
            $table->dropConstrainedForeignId('cancelled_by');
            $table->dropColumn(['put_back_in_service', 'cancelled_at']);
        });
    }
};
