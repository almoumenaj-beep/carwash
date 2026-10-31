<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\MeResource;
use Illuminate\Http\Request;

class MeController extends Controller
{
    /**
     * The signed-in staff member, their roles, permissions and branches.
     */
    public function __invoke(Request $request): MeResource
    {
        return MeResource::make($request->user()->load('tenant', 'roles'));
    }
}
