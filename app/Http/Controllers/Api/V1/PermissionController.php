<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Identity\Enums\Permission;
use App\Domain\Identity\Models\Role;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class PermissionController extends Controller
{
    /**
     * The permission catalog grouped by module, with translated labels, for the role editor.
     */
    public function index(): JsonResponse
    {
        Gate::authorize('viewAny', Role::class);

        $modules = collect(Permission::cases())
            ->groupBy(fn (Permission $permission) => $permission->module())
            ->map(fn ($permissions, string $module) => [
                'module' => $module,
                'label' => Permission::moduleLabel($module),
                'permissions' => $permissions->map(fn (Permission $permission) => [
                    'name' => $permission->value,
                    'label' => $permission->label(),
                ])->values(),
            ])
            ->values();

        return response()->json(['data' => $modules]);
    }
}
