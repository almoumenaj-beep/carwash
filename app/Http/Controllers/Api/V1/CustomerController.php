<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Crm\Actions\DeleteCrmRecord;
use App\Domain\Crm\Actions\SaveCustomer;
use App\Domain\Crm\Models\Customer;
use App\Domain\Identity\Enums\Permission;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCustomerRequest;
use App\Http\Requests\UpdateCustomerRequest;
use App\Http\Resources\CustomerResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

/**
 * Customers with their cars, shared by every branch of the car wash.
 */
class CustomerController extends Controller
{
    /**
     * Customers, newest first; `search` matches name, phone or plate (as typed at the counter).
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize(Permission::CustomersView->value);

        $customers = Customer::query()
            ->when($request->filled('search'), fn ($query) => $query->search((string) $request->input('search')))
            ->with('vehicles')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->cursorPaginate(20);

        return CustomerResource::collection($customers);
    }

    public function store(StoreCustomerRequest $request, SaveCustomer $saveCustomer): JsonResponse
    {
        return CustomerResource::make($saveCustomer->create($request->user(), $request->validated())->load('vehicles'))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function show(Customer $customer): CustomerResource
    {
        Gate::authorize(Permission::CustomersView->value);

        return CustomerResource::make($customer->load('vehicles'));
    }

    public function update(UpdateCustomerRequest $request, Customer $customer, SaveCustomer $saveCustomer): CustomerResource
    {
        return CustomerResource::make($saveCustomer->update($request->user(), $customer, $request->validated())->load('vehicles'));
    }

    /**
     * Delete a customer and their cars; refused once they have visits on record.
     */
    public function destroy(Request $request, Customer $customer, DeleteCrmRecord $deleteCrmRecord): Response
    {
        Gate::authorize(Permission::CustomersDelete->value);

        $deleteCrmRecord->handle($request->user(), $customer);

        return response()->noContent();
    }
}
