<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Platform\Models\Tenant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class SettingsApiTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    private Tenant $tenant;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = $this->createTenantWithRoles();
    }

    public function test_every_staff_member_reads_the_settings_with_bahraini_defaults(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Washer));

        $this->getJson('/api/v1/settings')
            ->assertOk()
            ->assertJsonPath('data.currency', 'BHD')
            ->assertJsonPath('data.currency_decimals', 3)
            ->assertJsonPath('data.timezone', 'Asia/Bahrain')
            ->assertJsonPath('data.vat_rate', 10)
            ->assertJsonPath('data.prices_include_vat', true);
    }

    public function test_owner_updates_the_settings_and_the_change_is_audited(): void
    {
        $owner = $this->createStaff($this->tenant, DefaultRole::Owner);
        Sanctum::actingAs($owner);

        $this->patchJson('/api/v1/settings', [
            'name' => 'Sparkle Wash',
            'vat_rate' => 12.5,
            'prices_include_vat' => false,
            'vat_number' => '200012345600002',
            'locale' => 'en',
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Sparkle Wash')
            ->assertJsonPath('data.vat_rate', 12.5)
            ->assertJsonPath('data.prices_include_vat', false);

        $this->assertSame(1250, $this->tenant->fresh()->vat_rate_bps);
        $this->assertDatabaseHas('activity_log', ['event' => 'settings.updated', 'subject_id' => $this->tenant->id, 'causer_id' => $owner->id]);
    }

    public function test_the_currency_cannot_be_changed_through_settings(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Owner));

        $this->patchJson('/api/v1/settings', ['currency' => 'USD', 'name' => 'Renamed'])->assertOk();

        $this->assertSame('BHD', $this->tenant->fresh()->currency);
    }

    public function test_settings_values_are_validated(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Owner));

        $this->patchJson('/api/v1/settings', ['vat_rate' => 150, 'timezone' => 'Mars/Base', 'locale' => 'fr'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['vat_rate', 'timezone', 'locale']);
    }

    public function test_staff_without_settings_permission_cannot_change_settings(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::BranchManager, allBranches: true));

        $this->patchJson('/api/v1/settings', ['vat_rate' => 0])->assertForbidden();
        $this->assertSame(1000, $this->tenant->fresh()->vat_rate_bps);
    }
}
