<?php

namespace Database\Seeders;

use App\Domain\Platform\Models\Branch;
use App\Domain\Platform\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $tenant = Tenant::factory()->create(['name' => 'Demo Car Wash', 'slug' => 'demo']);

        Branch::factory()->for($tenant)->create(['name' => 'Main Branch', 'code' => 'MAIN']);

        User::factory()->forTenant($tenant)->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);
    }
}
