<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Domain\Offers\Models\Offer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class OfferApiTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
    }

    public function test_the_owner_manages_offers(): void
    {
        Sanctum::actingAs($this->createStaff($this->tenant, DefaultRole::Owner));

        $created = $this->postJson('/api/v1/offers', [
            'title' => 'Two washes for the price of one',
            'description' => 'Weekdays only',
            'price' => 2000,
            'expires_on' => '2027-01-31',
        ])->assertCreated();
        $offerId = $created->json('data.id');

        $this->patchJson("/api/v1/offers/{$offerId}", ['title' => 'Two for one', 'is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->getJson('/api/v1/offers')->assertOk()->assertJsonCount(1, 'data');

        $this->deleteJson("/api/v1/offers/{$offerId}")->assertNoContent();
        $this->assertSame(0, $this->inTenant(fn () => Offer::query()->count()));
    }

    public function test_staff_without_settings_manage_cannot_touch_offers(): void
    {
        Sanctum::actingAs($this->cashier);

        $this->getJson('/api/v1/offers')->assertForbidden();
        $this->postJson('/api/v1/offers', ['title' => 'Sneaky'])->assertForbidden();
    }
}
