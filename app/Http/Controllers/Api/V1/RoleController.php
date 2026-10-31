<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Actions\CreateRole;
use App\Domain\Identity\Actions\DeleteRole;
use App\Domain\Identity\Actions\RenameRole;
use App\Domain\Identity\Models\Role;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRoleRequest;
use App\Http\Requests\UpdateRoleRequest;
use App\Http\Resources\RoleResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

class RoleController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Role::class);

        $roles = Role::query()
            ->ofTenant($request->user()->tenant_id)
            ->with('permissions')
            ->withCount('users')
            ->orderBy('id')
            ->get();

        return RoleResource::collection($roles);
    }

    public function store(StoreRoleRequest $request, CreateRole $createRole): JsonResponse
    {
        $role = $createRole->handle($request->user(), $request->validated('name'), $request->validated('permissions'));

        return RoleResource::make($role->load('permissions')->loadCount('users'))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function show(Role $role): RoleResource
    {
        Gate::authorize('view', $role);

        return RoleResource::make($role->load('permissions')->loadCount('users'));
    }

    public function update(UpdateRoleRequest $request, Role $role, RenameRole $renameRole): RoleResource
    {
        $renameRole->handle($request->user(), $role, $request->validated('name'));

        return RoleResource::make($role->load('permissions')->loadCount('users'));
    }

    public function destroy(Request $request, Role $role, DeleteRole $deleteRole): Response
    {
        Gate::authorize('delete', $role);

        $deleteRole->handle($request->user(), $role);

        return response()->noContent();
    }
}
