<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Maintenance done on a piece of equipment: periodic servicing or a repair. A cost is recorded as an
     * expense of the equipment's branch (`expense_id`), paid or owed to the supplier who did the work.
     */
    public function up(): void
    {
        Schema::create('equipment_maintenances', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->foreignUuid('equipment_id')->constrained('equipment')->cascadeOnDelete();
            $table->string('kind', 20);
            $table->date('performed_on');
            $table->string('description')->nullable();
            $table->unsignedBigInteger('cost')->default(0);
            $table->foreignUuid('supplier_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('expense_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('created_by')->constrained('users');
            $table->timestamps();

            $table->index(['tenant_id', 'equipment_id', 'performed_on'], 'equipment_maintenances_history_index');
            $table->foreign('tenant_id')->references('id')->on('tenants');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('equipment_maintenances');
    }
};
