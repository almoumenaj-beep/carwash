<?php

namespace App\Domain\Identity\Models;

use App\Domain\Identity\Policies\DevicePolicy;
use App\Domain\Platform\Tenancy\BelongsToTenant;
use Database\Factories\DeviceFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Laravel\Sanctum\PersonalAccessToken;
use Laravel\Sanctum\Sanctum;

/**
 * A phone or tablet registered by a password login. Holds at most one session, and its secret
 * lets staff switch users on it with a PIN.
 */
#[Fillable(['identifier', 'name', 'platform'])]
#[Hidden(['secret_hash'])]
#[UseFactory(DeviceFactory::class)]
#[UsePolicy(DevicePolicy::class)]
class Device extends Model
{
    /** @use HasFactory<DeviceFactory> */
    use BelongsToTenant, HasFactory, HasUuids;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'last_login_at' => 'datetime',
            'revoked_at' => 'datetime',
        ];
    }

    /**
     * The secret is long and random, so a fast hash is enough and keeps device lookups cheap.
     */
    public static function hashSecret(string $secret): string
    {
        return hash('sha256', $secret);
    }

    public function matchesSecret(string $secret): bool
    {
        return hash_equals($this->secret_hash, self::hashSecret($secret));
    }

    public function isRevoked(): bool
    {
        return $this->revoked_at !== null;
    }

    /**
     * @return HasMany<PersonalAccessToken, $this>
     */
    public function tokens(): HasMany
    {
        return $this->hasMany(Sanctum::personalAccessTokenModel(), 'device_id');
    }
}
