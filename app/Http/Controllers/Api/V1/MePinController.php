<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\SetUserPin;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdatePinRequest;
use Illuminate\Http\Response;

class MePinController extends Controller
{
    /**
     * Set or change the signed-in staff member's PIN. Requires their current password.
     */
    public function update(UpdatePinRequest $request, SetUserPin $setUserPin): Response
    {
        $setUserPin->handle($request->user(), $request->validated('pin'));

        return response()->noContent();
    }
}
