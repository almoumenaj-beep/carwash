<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * The equipment permissions used to be granted to the default roles here; the equipment section was
     * removed, so nothing is granted anymore. Kept as an empty migration so existing databases keep their
     * migration history.
     */
    public function up(): void {}

    public function down(): void {}
};
