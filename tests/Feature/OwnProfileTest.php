<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\BuildsCarWash;
use Tests\TestCase;

class OwnProfileTest extends TestCase
{
    use BuildsCarWash, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->buildCarWash();
    }

    public function test_any_staff_member_edits_their_own_email_and_phone(): void
    {
        // The washer has no users.manage permission, but may still edit their own profile.
        Sanctum::actingAs($this->washer);

        $this->putJson('/api/v1/me/profile', ['email' => 'yousif@example.com', 'phone' => '36001122'])
            ->assertOk()
            ->assertJsonPath('data.name', $this->washer->name)
            ->assertJsonPath('data.email', 'yousif@example.com')
            ->assertJsonPath('data.phone', '36001122');

        $this->getJson('/api/v1/me')->assertJsonPath('data.email', 'yousif@example.com');
        $this->assertDatabaseHas('activity_log', ['event' => 'user.updated', 'subject_id' => $this->washer->id]);
    }

    public function test_a_staff_member_cannot_change_their_own_name(): void
    {
        Sanctum::actingAs($this->washer);

        $this->putJson('/api/v1/me/profile', ['name' => 'Changed', 'email' => 'yousif@example.com'])
            ->assertOk()
            ->assertJsonPath('data.name', $this->washer->name);
    }

    public function test_the_email_and_phone_must_stay_unique_and_at_least_one_must_remain(): void
    {
        $other = $this->createStaff($this->tenant, DefaultRole::Washer, [$this->branch]);
        $other->update(['email' => 'taken@example.com']);

        Sanctum::actingAs($this->washer);

        $this->putJson('/api/v1/me/profile', ['email' => 'taken@example.com'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('email');

        $this->washer->update(['phone' => null]);
        $this->putJson('/api/v1/me/profile', ['email' => null])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('phone');
    }

    public function test_a_staff_member_cannot_edit_someone_elses_profile_through_staff_management_without_permission(): void
    {
        $other = $this->createStaff($this->tenant, DefaultRole::Washer, [$this->branch]);

        Sanctum::actingAs($this->washer);
        $this->patchJson("/api/v1/users/{$other->id}", ['name' => 'Changed'])->assertForbidden();
    }
}
