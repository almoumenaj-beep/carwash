<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\SetOwnPassword;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateOwnPasswordRequest;
use Illuminate\Http\Response;

class MePasswordController extends Controller
{
    /**
     * Changes the signed-in staff member's own password. Requires their current password.
     */
    public function update(UpdateOwnPasswordRequest $request, SetOwnPassword $setOwnPassword): Response
    {
        $setOwnPassword->handle($request->user(), $request->validated('password'));

        return response()->noContent();
    }
}
