<?php

namespace Tests\Feature;

use App\Domain\Identity\Enums\DefaultRole;
use App\Http\Exceptions\ProblemDetails;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\Sanctum;
use RuntimeException;
use Tests\Concerns\InteractsWithTenants;
use Tests\TestCase;

class ProblemDetailsTest extends TestCase
{
    use InteractsWithTenants, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Route::middleware('api')->get('api/testing/explode', fn () => throw new RuntimeException('secret internals'));
    }

    public function test_validation_errors_are_problem_details(): void
    {
        $response = $this->postJson('/api/v1/auth/login', []);

        $response->assertUnprocessable()
            ->assertHeader('Content-Type', ProblemDetails::CONTENT_TYPE)
            ->assertJsonPath('type', ProblemDetails::TYPE_PREFIX.'validation-failed')
            ->assertJsonPath('title', 'The given data was invalid')
            ->assertJsonPath('status', 422)
            ->assertJsonPath('instance', '/api/v1/auth/login')
            ->assertJsonValidationErrors(['login', 'password', 'device_identifier', 'device_name']);
        $this->assertStringStartsWith('The login field is required.', $response->json('detail'));
    }

    public function test_validation_messages_are_arabic_when_requested(): void
    {
        $this->withHeader('Accept-Language', 'ar')
            ->postJson('/api/v1/auth/login', [])
            ->assertJsonPath('title', 'البيانات المرسلة غير صالحة')
            ->assertJsonPath('errors.login.0', 'حقل البريد الإلكتروني أو رقم الجوال مطلوب.')
            ->assertJsonPath('errors.password.0', 'حقل كلمة المرور مطلوب.');
    }

    public function test_missing_authentication_is_a_translated_problem(): void
    {
        $this->withHeader('Accept-Language', 'ar')
            ->getJson('/api/v1/me')
            ->assertUnauthorized()
            ->assertJsonPath('type', ProblemDetails::TYPE_PREFIX.'unauthenticated')
            ->assertJsonPath('detail', 'يجب تسجيل الدخول أولاً.');
    }

    public function test_denied_actions_explain_why(): void
    {
        Sanctum::actingAs($this->createStaff($this->createTenantWithRoles(), DefaultRole::Cashier));

        $this->getJson('/api/v1/roles')
            ->assertForbidden()
            ->assertJsonPath('type', ProblemDetails::TYPE_PREFIX.'forbidden')
            ->assertJsonPath('detail', 'This action is unauthorized.');
    }

    public function test_not_found_does_not_reveal_which_model_was_looked_up(): void
    {
        config(['app.debug' => false]);
        Sanctum::actingAs($this->createStaff($this->createTenantWithRoles(), DefaultRole::Owner));

        $response = $this->getJson('/api/v1/roles/999999');

        $response->assertNotFound()
            ->assertJsonPath('type', ProblemDetails::TYPE_PREFIX.'not-found')
            ->assertJsonPath('detail', 'The requested resource was not found.');
        $this->assertStringNotContainsString('Domain', $response->getContent());
    }

    public function test_unknown_api_routes_are_translated_problems(): void
    {
        $this->withHeader('Accept-Language', 'ar')
            ->getJson('/api/v1/does-not-exist')
            ->assertNotFound()
            ->assertJsonPath('type', ProblemDetails::TYPE_PREFIX.'not-found')
            ->assertJsonPath('detail', 'العنصر المطلوب غير موجود.');
    }

    public function test_rate_limited_requests_say_when_to_retry(): void
    {
        foreach (range(1, 5) as $attempt) {
            $this->postJson('/api/v1/auth/login', ['login' => 'x@example.com', 'password' => 'x', 'device_identifier' => 'd', 'device_name' => 'd']);
        }

        $response = $this->postJson('/api/v1/auth/login', ['login' => 'x@example.com', 'password' => 'x', 'device_identifier' => 'd', 'device_name' => 'd']);

        $response->assertTooManyRequests()
            ->assertHeader('Retry-After')
            ->assertJsonPath('type', ProblemDetails::TYPE_PREFIX.'too-many-requests');
        $this->assertGreaterThan(0, $response->json('retry_after'));
    }

    public function test_server_errors_hide_internals_outside_debug_mode(): void
    {
        config(['app.debug' => false]);

        $response = $this->getJson('/api/testing/explode');

        $response->assertInternalServerError()
            ->assertJsonPath('type', ProblemDetails::TYPE_PREFIX.'server-error')
            ->assertJsonPath('detail', 'Something went wrong on our side. Please try again.')
            ->assertJsonMissingPath('debug');
        $this->assertStringNotContainsString('secret internals', $response->getContent());
    }

    public function test_server_errors_include_debug_details_in_debug_mode(): void
    {
        config(['app.debug' => true]);

        $this->getJson('/api/testing/explode')
            ->assertInternalServerError()
            ->assertJsonPath('detail', 'secret internals')
            ->assertJsonPath('debug.exception', RuntimeException::class);
    }
}
