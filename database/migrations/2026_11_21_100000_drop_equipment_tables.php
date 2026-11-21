<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Drops the equipment section end to end: machines, their maintenance records and breakdowns, and the
     * equipment permissions in the catalog. Repair costs are recorded as ordinary expenses from now on
     * (the default "maintenance and equipment" expense category stays).
     */
    public function up(): void
    {
        Schema::dropIfExists('equipment_breakdowns');
        Schema::dropIfExists('equipment_maintenances');
        Schema::dropIfExists('equipment');

        $tables = config('permission.table_names');

        DB::table($tables['role_has_permissions'])
            ->whereIn('permission_id', function ($query) use ($tables): void {
                $query->select('id')->from($tables['permissions'])
                    ->whereIn('name', ['equipment.view', 'equipment.manage']);
            })
            ->delete();

        DB::table($tables['permissions'])->whereIn('name', ['equipment.view', 'equipment.manage'])->delete();
    }

    public function down(): void {}
};
