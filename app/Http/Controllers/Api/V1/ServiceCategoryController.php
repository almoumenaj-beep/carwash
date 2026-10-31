<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Catalog\Actions\DeleteCatalogEntry;
use App\Domain\Catalog\Actions\SaveCatalogEntry;
use App\Domain\Catalog\Models\ServiceCategory;
use App\Domain\Identity\Enums\Permission;
use App\Http\Controllers\Controller;
use App\Http\Requests\SaveServiceCategoryRequest;
use App\Http\Resources\ServiceCategoryResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Categories that group services on the menu. Readable by all staff; changed with services.manage.
 */
class ServiceCategoryController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return ServiceCategoryResource::collection(
            ServiceCategory::query()->withCount('services')->orderBy('sort_order')->orderBy('name')->get(),
        );
    }

    public function store(SaveServiceCategoryRequest $request, SaveCatalogEntry $saveCatalogEntry): JsonResponse
    {
        $category = $saveCatalogEntry->create($request->user(), ServiceCategory::class, $request->validated());

        return ServiceCategoryResource::make($category->loadCount('services'))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function update(SaveServiceCategoryRequest $request, ServiceCategory $serviceCategory, SaveCatalogEntry $saveCatalogEntry): ServiceCategoryResource
    {
        return ServiceCategoryResource::make(
            $saveCatalogEntry->update($request->user(), $serviceCategory, $request->validated())->loadCount('services'),
        );
    }

    /**
     * Delete a category; its services stay, without a category.
     */
    public function destroy(Request $request, ServiceCategory $serviceCategory, DeleteCatalogEntry $deleteCatalogEntry): Response
    {
        Gate::authorize(Permission::ServicesManage->value);

        $deleteCatalogEntry->handle($request->user(), $serviceCategory);

        return response()->noContent();
    }
}
