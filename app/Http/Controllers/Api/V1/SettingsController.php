<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Platform\Actions\UpdateTenantSettings;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateSettingsRequest;
use App\Http\Resources\SettingsResource;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    /**
     * The car wash's settings (currency, VAT, language, time zone). Readable by all staff,
     * since every screen that shows money needs them.
     */
    public function show(Request $request): SettingsResource
    {
        return SettingsResource::make($request->user()->tenant);
    }

    /**
     * Change the settings. Requires settings.manage; the currency cannot be changed here.
     */
    public function update(UpdateSettingsRequest $request, UpdateTenantSettings $updateTenantSettings): SettingsResource
    {
        return SettingsResource::make(
            $updateTenantSettings->handle($request->user(), $request->user()->tenant, $request->validated()),
        );
    }
}
