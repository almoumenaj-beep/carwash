// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CarWash';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle => 'Sign in to your car wash';

  @override
  String get loginField => 'Email or phone';

  @override
  String get passwordField => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get switchUserWithPin => 'Switch user with PIN';

  @override
  String get signInWithPassword => 'Sign in with password instead';

  @override
  String get pinTitle => 'Who is working now?';

  @override
  String get pinField => 'PIN';

  @override
  String get pinSignInButton => 'Continue';

  @override
  String get noStaffWithPin =>
      'Nobody on this device has a PIN yet. Sign in with a password and set one from your profile.';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get ownerBadge => 'Owner';

  @override
  String get rolesSection => 'Roles';

  @override
  String get branchesSection => 'Branches';

  @override
  String get allBranches => 'All branches';

  @override
  String get noBranches => 'No branches assigned yet';

  @override
  String get permissionsSection => 'Permissions';

  @override
  String permissionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permissions',
      one: '1 permission',
      zero: 'No permissions',
    );
    return '$_temp0';
  }

  @override
  String get switchUser => 'Switch user';

  @override
  String get signOut => 'Sign out';

  @override
  String get changeLanguage => 'العربية';

  @override
  String get setPin => 'Set PIN';

  @override
  String get currentPasswordField => 'Current password';

  @override
  String get newPinField => 'New PIN (4–6 digits)';

  @override
  String get confirmPinField => 'Confirm PIN';

  @override
  String get pinMustBeDigits => 'Use 4 to 6 digits';

  @override
  String get pinsDoNotMatch => 'PINs do not match';

  @override
  String get pinSaved => 'PIN saved';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get networkError => 'Cannot reach the server. Check your connection and try again.';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get listSeparator => ', ';

  @override
  String get rolesTitle => 'Roles';

  @override
  String get rolesSubtitle => 'Roles and their permissions';

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffSubtitle => 'Accounts, roles and branches';

  @override
  String get devicesTitle => 'Devices';

  @override
  String get devicesSubtitle => 'Phones and tablets signed in';

  @override
  String get newRole => 'New role';

  @override
  String get roleName => 'Role name';

  @override
  String get allPermissions => 'All permissions';

  @override
  String get ownerRoleLocked => 'The owner role always has every permission and cannot be changed.';

  @override
  String get readOnlyRole => 'You can view roles but not change them.';

  @override
  String staffCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count staff',
      one: '1 staff member',
      zero: 'No staff',
    );
    return '$_temp0';
  }

  @override
  String get deleteRole => 'Delete role';

  @override
  String deleteRoleConfirm(String name) {
    return 'Delete the role “$name”?';
  }

  @override
  String get newStaff => 'Add staff';

  @override
  String get staffName => 'Name';

  @override
  String get emailField => 'Email';

  @override
  String get phoneField => 'Phone';

  @override
  String get emailOrPhoneRequired => 'Enter an email or a phone number';

  @override
  String get passwordKeepHint => 'Leave empty to keep the current password';

  @override
  String get allBranchesSwitch => 'Works in all branches';

  @override
  String get activeSwitch => 'Account active';

  @override
  String get inactive => 'Deactivated';

  @override
  String get noDevices => 'No devices have signed in yet';

  @override
  String get revokeDevice => 'Revoke';

  @override
  String revokeDeviceConfirm(String name) {
    return 'Sign out “$name” and stop PIN switching on it?';
  }

  @override
  String lastSignIn(String date) {
    return 'Last sign-in: $date';
  }

  @override
  String get revoked => 'Revoked';

  @override
  String get settingsTitle => 'Car wash settings';

  @override
  String get settingsSubtitle => 'Name, VAT, language and time zone';

  @override
  String get carWashName => 'Car wash name';

  @override
  String get currency => 'Currency';

  @override
  String get currencyLocked => 'Set when the account was opened; it cannot be changed';

  @override
  String currencyDecimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decimal places',
      one: '1 decimal place',
      zero: 'no decimals',
    );
    return '$_temp0';
  }

  @override
  String get vatSection => 'VAT';

  @override
  String get vatRate => 'VAT rate';

  @override
  String get vatRateInvalid => 'Enter a rate between 0 and 100';

  @override
  String get pricesIncludeVat => 'Prices include VAT';

  @override
  String get vatNumber => 'VAT registration number';

  @override
  String get languageField => 'Language';

  @override
  String get timezoneField => 'Time zone';

  @override
  String get arabicLanguage => 'العربية';

  @override
  String get englishLanguage => 'English';

  @override
  String get branchesTitle => 'Branches';

  @override
  String get branchesSubtitle => 'Branches, opening hours and bays';

  @override
  String get newBranch => 'New branch';

  @override
  String get branchName => 'Branch name';

  @override
  String get branchCode => 'Branch code';

  @override
  String get branchCodeHint => 'A short code, e.g. MAIN or RIF-1';

  @override
  String get addressField => 'Address';

  @override
  String get branchActive => 'Branch is open for business';

  @override
  String get branchClosed => 'Closed';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get closedDay => 'Closed';

  @override
  String get opensAt => 'Opens';

  @override
  String get closesAt => 'Closes';

  @override
  String get baysSection => 'Bays';

  @override
  String get addBay => 'Add bay';

  @override
  String get bayName => 'Bay name';

  @override
  String get noBays => 'No bays yet. Add the wash bays or stations of this branch.';

  @override
  String get bayOutOfService => 'Out of service';

  @override
  String get deleteBranch => 'Delete branch';

  @override
  String deleteBranchConfirm(String name) {
    return 'Delete “$name” permanently? This is only possible for a branch that was never used; otherwise, close it instead.';
  }

  @override
  String get branchDeleted => 'Branch deleted';

  @override
  String get accountTitle => 'My account';

  @override
  String get noSectionsYet => 'Your role has no sections yet. Ask the owner to give you the permissions you need.';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersSubtitle => 'Customers and their cars';

  @override
  String get newCustomer => 'New customer';

  @override
  String get customerSearchHint => 'Search by name, phone or plate';

  @override
  String get noCustomers => 'No customers yet';

  @override
  String get noCustomerMatches => 'No customer matches. Register them as a new customer.';

  @override
  String get customerName => 'Customer name';

  @override
  String get notesField => 'Notes';

  @override
  String get marketingConsent => 'Agrees to receive offers and messages';

  @override
  String get marketingConsentHint => 'Ask the customer; marketing messages are sent only with their consent';

  @override
  String get vehiclesSection => 'Cars';

  @override
  String get addVehicle => 'Add car';

  @override
  String get noVehicles => 'No cars yet';

  @override
  String get plateNumber => 'Plate number';

  @override
  String get vehicleSize => 'Vehicle size';

  @override
  String get sizeUnknown => 'Size not set';

  @override
  String get vehicleMake => 'Make';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleColor => 'Colour';

  @override
  String get catalogTitle => 'Services & prices';

  @override
  String get catalogSubtitle => 'Services, add-ons, vehicle sizes and prices';

  @override
  String get newService => 'New service';

  @override
  String get noServices => 'No services yet. Add your services and their prices.';

  @override
  String get serviceName => 'Service name';

  @override
  String get categoryField => 'Category';

  @override
  String get noCategory => 'Uncategorised';

  @override
  String get durationField => 'Duration (minutes)';

  @override
  String get descriptionField => 'Description';

  @override
  String get isAddon => 'Add-on (sold with a main service)';

  @override
  String get serviceActive => 'Available for sale';

  @override
  String get pricesSection => 'Prices';

  @override
  String get pricesIncludeVatHint => 'Prices charged to the customer, VAT included';

  @override
  String get pricesExcludeVatHint => 'Prices before VAT';

  @override
  String get samePriceAllSizes => 'Same price for every vehicle size';

  @override
  String get priceAllSizes => 'Price (every size)';

  @override
  String branchPricesFor(String branch) {
    return 'Prices at $branch';
  }

  @override
  String get branchPricesHint => 'Leave empty to use the general price';

  @override
  String amountInvalid(String example) {
    return 'Enter an amount like $example';
  }

  @override
  String get addonsSection => 'Add-ons';

  @override
  String fromPrice(String price) {
    return 'from $price';
  }

  @override
  String get unpriced => 'No price';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get inactiveLabel => 'Inactive';

  @override
  String get sizesTitle => 'Vehicle sizes';

  @override
  String get categoriesTitle => 'Service categories';

  @override
  String get addSize => 'Add size';

  @override
  String get addCategory => 'Add category';

  @override
  String get nameField => 'Name';

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
      zero: 'No services',
    );
    return '$_temp0';
  }

  @override
  String deleteEntryConfirm(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get dayMon => 'Monday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayFri => 'Friday';

  @override
  String get queueTitle => 'Queue';

  @override
  String get queueSubtitle => 'Check cars in and follow them through the wash';

  @override
  String get queueTabWashing => 'Washing';

  @override
  String get queueTabToday => 'Today';

  @override
  String get queueEmpty => 'No cars here.';

  @override
  String get noBranchAssigned => 'You are not assigned to a branch yet.';

  @override
  String get statusWaiting => 'Waiting';

  @override
  String get statusInProgress => 'Washing';

  @override
  String get statusQualityCheck => 'Quality check';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get actionStart => 'Start washing';

  @override
  String get actionQualityCheck => 'To quality check';

  @override
  String get actionReady => 'Mark ready';

  @override
  String get actionDeliver => 'Hand over';

  @override
  String get actionBackToWaiting => 'Back to waiting';

  @override
  String get actionBackToWashing => 'Wash again';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelReasonField => 'Reason for cancelling';

  @override
  String get keepOrder => 'Keep';

  @override
  String elapsedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count min', zero: 'just now');
    return '$_temp0';
  }

  @override
  String get walkIn => 'Walk-in';

  @override
  String get checkInTitle => 'Check in a car';

  @override
  String get checkIn => 'Check in';

  @override
  String checkedIn(String reference) {
    return '$reference checked in';
  }

  @override
  String get matchingCars => 'Registered cars';

  @override
  String get shiftTitle => 'Cashier';

  @override
  String get shiftSubtitle => 'Open the cashier, count and match the cash at close';

  @override
  String get noOpenShift => 'The cashier is not open. Count the cash in the drawer to open it.';

  @override
  String get openingFloatField => 'Cash in the drawer at opening';

  @override
  String get openingFloatHint => 'Leave empty if the drawer is empty.';

  @override
  String get openShift => 'Open cashier';

  @override
  String shiftOpenSince(String time) {
    return 'Open since $time';
  }

  @override
  String get shiftInvoices => 'Invoices';

  @override
  String get shiftCashTaken => 'Cash taken';

  @override
  String get shiftDiscounts => 'Discounts given';

  @override
  String get expectedCash => 'Expected in the drawer';

  @override
  String get closeShift => 'Close cashier';

  @override
  String get countedCashField => 'Cash counted in the drawer';

  @override
  String get drawerMatches => 'The drawer matches';

  @override
  String drawerShort(String amount) {
    return 'Short by $amount';
  }

  @override
  String drawerOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String get varianceNoteField => 'Why does it not match?';

  @override
  String get varianceLabel => 'Difference';

  @override
  String get shiftClosed => 'Cashier closed';

  @override
  String get openShiftFirst => 'Open the cashier to take payment.';

  @override
  String get checkoutTitle => 'Payment';

  @override
  String get collectPayment => 'Collect payment';

  @override
  String get payOnly => 'Pay only';

  @override
  String get payAndDeliver => 'Pay and hand over';

  @override
  String get subtotalLabel => 'Services';

  @override
  String get discountLabel => 'Discount';

  @override
  String vatIncludedLabel(String rate) {
    return 'Includes VAT $rate%';
  }

  @override
  String vatAddedLabel(String rate) {
    return 'VAT $rate%';
  }

  @override
  String discountLimitHint(String limit) {
    return 'Your limit: $limit%';
  }

  @override
  String discountOverLimit(String limit) {
    return 'Above your limit of $limit%';
  }

  @override
  String get discountReasonField => 'Reason for the discount';

  @override
  String get cashReceivedField => 'Cash received';

  @override
  String get cashTooLittle => 'Less than the total';

  @override
  String changeDue(String amount) {
    return 'Change: $amount';
  }

  @override
  String get paidTitle => 'Paid';

  @override
  String get paidBadge => 'Paid';

  @override
  String get done => 'Done';

  @override
  String get darkMode => 'Night mode';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get inventorySubtitle => 'Materials, stock, purchases and counts';

  @override
  String get stockTab => 'Stock';

  @override
  String get purchasesTab => 'Purchases';

  @override
  String get newPurchase => 'New purchase';

  @override
  String get addMaterial => 'Add material';

  @override
  String get noMaterials => 'No materials yet. Add the materials you use, such as shampoo or towels.';

  @override
  String lowStock(String min, String unit) {
    return 'Low: minimum $min $unit';
  }

  @override
  String minStockLabel(String min, String unit) {
    return 'Minimum $min $unit';
  }

  @override
  String unitCostLabel(String cost, String unit) {
    return 'Last cost $cost per $unit';
  }

  @override
  String get stockCount => 'Stock count';

  @override
  String get countedQuantity => 'Quantity counted';

  @override
  String get stockHistory => 'History';

  @override
  String get noMovements => 'No movements yet.';

  @override
  String get movementPurchase => 'Purchase';

  @override
  String get movementConsumption => 'Used by a wash';

  @override
  String get movementCount => 'Stock count';

  @override
  String get quantityInvalid => 'Enter a quantity, e.g. 2.5';

  @override
  String get unitField => 'Unit';

  @override
  String get unitHint => 'e.g. L, kg, pc';

  @override
  String get minStockField => 'Minimum stock';

  @override
  String get minStockHint => 'You are warned when stock falls to this level.';

  @override
  String get noPurchases => 'No purchases yet.';

  @override
  String get materialsSection => 'Materials';

  @override
  String get addMaterialLine => 'Add material';

  @override
  String get quantityField => 'Quantity';

  @override
  String get unitPriceField => 'Price per unit';

  @override
  String get addAtLeastOneMaterial => 'Add at least one material.';

  @override
  String get purchaseCategoryHint => 'The purchase is also recorded as an expense in this category.';

  @override
  String get serviceMaterials => 'Materials used';

  @override
  String get serviceMaterialsHint =>
      'What one sale of this service uses. It is taken from the branch\'s stock when the wash starts.';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get expensesSubtitle => 'Spending, suppliers and recurring bills';

  @override
  String get owedTab => 'Owed';

  @override
  String get suppliersTab => 'Suppliers';

  @override
  String get recurringTab => 'Recurring';

  @override
  String get newExpense => 'New expense';

  @override
  String get expenseCategories => 'Expense categories';

  @override
  String get expenseCategory => 'Category';

  @override
  String get amountField => 'Amount';

  @override
  String get paymentMethodField => 'Paid by';

  @override
  String get payFromDrawer => 'From the drawer';

  @override
  String get payCash => 'Cash';

  @override
  String get payBankTransfer => 'Bank transfer';

  @override
  String get payCard => 'Card';

  @override
  String get notPaidYet => 'Not paid yet';

  @override
  String get payFromDrawerHint => 'Taken from the cashier drawer today; the count at close expects it.';

  @override
  String get supplierField => 'Supplier';

  @override
  String get noSupplier => 'No supplier';

  @override
  String get owedToSupplierHint => 'Recorded as owed to this supplier until paid.';

  @override
  String get expenseDate => 'Date';

  @override
  String get payExpense => 'Pay with';

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String get totalOwed => 'Total owed';

  @override
  String get totalSpent => 'Total';

  @override
  String get nothingOwed => 'Nothing is owed.';

  @override
  String get noExpenses => 'No expenses in this period.';

  @override
  String get recurringBadge => 'Recurring';

  @override
  String get addSupplier => 'Add supplier';

  @override
  String get noSuppliers => 'No suppliers yet.';

  @override
  String owedAmount(String amount) {
    return 'Owed $amount';
  }

  @override
  String get addRecurring => 'Add recurring expense';

  @override
  String get recurringHint => 'On its due date a recurring expense is recorded as owed, until it is paid.';

  @override
  String get noRecurring => 'No recurring expenses.';

  @override
  String nextDue(String date) {
    return 'Next: $date';
  }

  @override
  String get nextDueField => 'Next due date';

  @override
  String get recurringDescriptionHint => 'e.g. Shop rent';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get frequencyYearly => 'Yearly';

  @override
  String get cashPaidOut => 'Expenses paid from the drawer';

  @override
  String get expensesTotal => 'Expenses';

  @override
  String get netTotal => 'Net';

  @override
  String get dailySalesTitle => 'Daily sales';

  @override
  String get dailySalesSubtitle => 'Sales, cars and staff for any day';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get today => 'Today';

  @override
  String get noSalesThatDay => 'No sales or cars on this day.';

  @override
  String get salesTotal => 'Sales';

  @override
  String get averageTicket => 'Average invoice';

  @override
  String get vatTotal => 'VAT';

  @override
  String get carsCheckedIn => 'Cars checked in';

  @override
  String get carsInQueue => 'Still in the queue';

  @override
  String get byCashier => 'Cashiers';

  @override
  String get byHour => 'Sales by hour';

  @override
  String invoicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count invoices', one: '1 invoice');
    return '$_temp0';
  }

  @override
  String carsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count cars', one: '1 car');
    return '$_temp0';
  }

  @override
  String get chooseWasher => 'Choose the washer who will wash the car.';

  @override
  String get noWashersInBranch => 'No staff work at this branch yet; add them under Staff.';

  @override
  String get isPackage => 'Package';

  @override
  String get isPackageHint => 'Bundles existing services at a discount';

  @override
  String get packagesSection => 'Packages';

  @override
  String get packageServicesSection => 'Services in the package';

  @override
  String get packageNeedsTwoServices => 'Choose at least two services';

  @override
  String get packageDiscountSection => 'Package discount';

  @override
  String get discountPercent => 'Percentage';

  @override
  String get packageDiscountField => 'Discount';

  @override
  String get packagePricesSection => 'Price per size';

  @override
  String discountOff(String discount) {
    return '$discount off';
  }

  @override
  String packageSaves(String amount) {
    return 'Saves $amount';
  }

  @override
  String get inspectionHint => 'Tick each service that was done properly';

  @override
  String get passInspection => 'Passed – ready';

  @override
  String get inspectionPassed => 'Passed the check';

  @override
  String get inspectionFailed => 'Sent back for rework';

  @override
  String get staffPinField => 'PIN (4–6 digits)';

  @override
  String get staffPinHint => 'Lets them switch in on a shared device from “Switch user”';

  @override
  String get staffPinKeepHint => 'Has a PIN; leave empty to keep it';

  @override
  String get maxDiscountField => 'Largest discount';

  @override
  String maxDiscountHint(String limit) {
    return 'Up to $limit% (your own limit)';
  }

  @override
  String get percentInvalid => 'Enter a percentage from 0 to 100';

  @override
  String get registerWalkInHint => 'Optional: the customer and car are saved with it';

  @override
  String get servicesSection => 'Services';

  @override
  String get chooseSizeForPrices => 'Services, packages and add-ons show with their prices for that size.';

  @override
  String get chooseMainService => 'Choose at least one main service.';

  @override
  String get bayField => 'Bay';

  @override
  String get noBayYet => 'Not yet';

  @override
  String get washersSection => 'Washers';

  @override
  String get orderTotal => 'Total';

  @override
  String aboutMinutes(int count) {
    return 'about $count min';
  }

  @override
  String checkedInBy(String name) {
    return 'Checked in by $name';
  }

  @override
  String get historyTitle => 'History';

  @override
  String get assignmentTitle => 'Bay, washers and notes';

  @override
  String cancelledBecause(String reason) {
    return 'Cancelled: $reason';
  }

  @override
  String get clockInAt => 'Clock in at';

  @override
  String get notClockedIn => 'You have not clocked in';

  @override
  String clockedInSince(String time) {
    return 'At work since $time';
  }

  @override
  String get clockIn => 'Clock in';

  @override
  String get clockOut => 'Clock out';

  @override
  String get staffAffairsTitle => 'Staff affairs';

  @override
  String get staffAffairsSubtitle => 'Pay, commission, attendance and payroll';

  @override
  String get employeesTab => 'Employees';

  @override
  String get attendanceTab => 'Attendance';

  @override
  String get payrollTab => 'Payroll';

  @override
  String get noCommission => 'No commission';

  @override
  String commissionPerCar(String amount) {
    return '$amount per car';
  }

  @override
  String commissionPercent(String percent) {
    return '$percent% of each car';
  }

  @override
  String salaryLabel(String amount) {
    return 'Salary $amount';
  }

  @override
  String get monthlySalaryField => 'Monthly salary';

  @override
  String get commissionField => 'Commission';

  @override
  String get noCommissionShort => 'None';

  @override
  String get perCarShort => 'Per car';

  @override
  String get perCarField => 'Amount per car';

  @override
  String get percentOfCarField => 'Share of the final invoice amount';

  @override
  String get commissionSplitHint => 'Split equally when several washers share a car';

  @override
  String get noAttendance => 'No one clocked in on this day';

  @override
  String stillAtWork(String time) {
    return 'Since $time, still at work';
  }

  @override
  String hoursWorked(String hours) {
    return '$hours h';
  }

  @override
  String get calculateThisMonth => 'Calculate this month';

  @override
  String get calculateLastMonth => 'Last month';

  @override
  String get noPayroll => 'No payroll yet';

  @override
  String get payrollPaid => 'Paid';

  @override
  String get payrollDraft => 'Draft, recalculated until paid';

  @override
  String commissionAmount(String amount) {
    return 'Commission $amount';
  }

  @override
  String get payPayroll => 'Pay payroll';

  @override
  String get edit => 'Edit';

  @override
  String get notSet => 'Not set';

  @override
  String get branchField => 'Branch';

  @override
  String get equipmentTitle => 'Equipment and maintenance';

  @override
  String get equipmentSubtitle => 'Machines, maintenance due and breakdowns';

  @override
  String get addEquipment => 'Add equipment';

  @override
  String get editEquipment => 'Edit equipment';

  @override
  String get noEquipment =>
      'No equipment yet. Add pressure washers, vacuums and compressors to keep track of their maintenance.';

  @override
  String get equipmentInService => 'In service';

  @override
  String get equipmentOutOfService => 'Broken';

  @override
  String get equipmentRetired => 'Retired';

  @override
  String maintenanceOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return 'Maintenance overdue by $_temp0';
  }

  @override
  String get maintenanceDueToday => 'Maintenance due today';

  @override
  String maintenanceDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return 'Maintenance in $_temp0';
  }

  @override
  String maintenanceDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count machines need maintenance now',
      one: '1 machine needs maintenance now',
    );
    return '$_temp0';
  }

  @override
  String get reportBreakdown => 'Report a breakdown';

  @override
  String get backInService => 'Back in service';

  @override
  String get retireEquipment => 'Retire';

  @override
  String get recordMaintenance => 'Record maintenance';

  @override
  String get noPeriodicMaintenance => 'No periodic maintenance';

  @override
  String maintenanceEvery(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: 'day');
    return 'Maintenance every $_temp0';
  }

  @override
  String get nextMaintenance => 'Next maintenance';

  @override
  String get serialNumberField => 'Serial number';

  @override
  String get purchaseSection => 'Purchase';

  @override
  String get maintenanceHistory => 'Maintenance history';

  @override
  String get noMaintenanceYet => 'No maintenance recorded';

  @override
  String get periodicMaintenance => 'Periodic';

  @override
  String get repairMaintenance => 'Repair';

  @override
  String get equipmentNameField => 'Name';

  @override
  String get equipmentNameHint => 'e.g. Pressure washer 1';

  @override
  String get maintenanceIntervalField => 'Periodic maintenance every';

  @override
  String get daysUnit => 'days';

  @override
  String get maintenanceIntervalHint => 'Leave empty if it needs no periodic maintenance';

  @override
  String get maintenanceIntervalInvalid => 'Enter 1 to 3650 days';

  @override
  String get purchaseDateField => 'Purchase date';

  @override
  String get purchaseCostField => 'Purchase price';

  @override
  String get periodicMaintenanceHint => 'The next maintenance is counted from this one';

  @override
  String get repairMaintenanceHint => 'A broken machine goes back in service';

  @override
  String get maintenanceDateField => 'Date';

  @override
  String get whatWasDoneField => 'What was done?';

  @override
  String get maintenanceCostField => 'Cost';

  @override
  String get maintenanceCostHint => 'Optional: recorded as an expense of the branch';

  @override
  String get financialReportsTitle => 'Financial reports';

  @override
  String get financialReportsSubtitle => 'Profit and loss, cash flow and profitability';

  @override
  String get thisYear => 'This year';

  @override
  String get customPeriod => 'Custom';

  @override
  String get profitLossTab => 'Profit & loss';

  @override
  String get cashFlowTab => 'Cash flow';

  @override
  String get profitabilityTab => 'Profitability';

  @override
  String get noFiguresInPeriod => 'No sales or expenses in this period';

  @override
  String get profitLabel => 'Net profit';

  @override
  String get lossLabel => 'Net loss';

  @override
  String marginLabel(String percent) {
    return 'Margin $percent%';
  }

  @override
  String get revenueSection => 'Revenue';

  @override
  String get grossSales => 'Sales before discounts';

  @override
  String get netSales => 'Net sales';

  @override
  String get totalExpenses => 'Total expenses';

  @override
  String get ofWhichOwed => 'Of which still owed';

  @override
  String get profitLossNote =>
      'Net sales leave out VAT. Expenses count by their date, paid or owed: materials when bought, wages when payroll is paid.';

  @override
  String get moneyIn => 'Money in';

  @override
  String get moneyOut => 'Money out';

  @override
  String get netCashFlow => 'Net cash flow';

  @override
  String stillOwed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills still owed',
      one: '1 bill still owed',
      zero: 'Nothing owed',
    );
    return '$_temp0';
  }

  @override
  String get byDay => 'By day';

  @override
  String get cashFlowNote =>
      'Money in is what customers paid; money out is expenses actually paid, on the day paid. Owed is what is unpaid today.';

  @override
  String get byBranch => 'By branch';

  @override
  String get materialsCost => 'Materials';

  @override
  String get serviceProfitNote => 'Net sales after discounts and VAT, less an estimate of materials at today\'s costs.';

  @override
  String get payLabel => 'Pay';

  @override
  String get washerProfitNote =>
      'Each car\'s value is split between its washers; pay is salary and commission in the period\'s payrolls.';

  @override
  String get appointmentsTitle => 'Bookings';

  @override
  String get appointmentsSubtitle => 'Booked cars, checked in when they arrive';

  @override
  String get newBooking => 'New booking';

  @override
  String get changeBooking => 'Change booking';

  @override
  String get checkInBooking => 'Check in the booked car';

  @override
  String get book => 'Book';

  @override
  String bookedAt(String time) {
    return 'Booked for $time';
  }

  @override
  String get bookingPhoneHint => 'To reach the customer; needed when the car is not registered';

  @override
  String get bookingTimeSection => 'Time';

  @override
  String get chooseServicesForTimes => 'Choose the services to see the free times.';

  @override
  String get noFreeTimes => 'No free times on this day.';

  @override
  String get appointmentBooked => 'Booked';

  @override
  String get appointmentCheckedIn => 'Arrived';

  @override
  String get appointmentCancelled => 'Cancelled';

  @override
  String get appointmentNoShow => 'No-show';

  @override
  String get noBookingsThatDay => 'No bookings on this day';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get markNoShow => 'Did not come';

  @override
  String get openOrder => 'Open the order';

  @override
  String get back => 'Back';

  @override
  String get chooseSizeFirst => 'Choose the vehicle size first';

  @override
  String get autoClockedOut => 'clocked out automatically at closing';

  @override
  String get groupDaily => 'Every day';

  @override
  String get groupMore => 'Management';

  @override
  String get groupFinance => 'Finance';

  @override
  String get groupResources => 'Stock and equipment';

  @override
  String get groupPeople => 'Staff';

  @override
  String get groupSetup => 'Setup';

  @override
  String get manageCategories => 'Expense categories';

  @override
  String get manageCategoriesHint => 'Add, rename or switch off categories';

  @override
  String get appointmentConfirmed => 'Confirmed';

  @override
  String get appointmentLate => 'Late';

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get confirmBookingHint => 'Once the customer says they are coming';

  @override
  String get allFilter => 'All';

  @override
  String get graceMinutesField => 'Wait for late bookings (minutes)';

  @override
  String get minutesUnit => 'min';

  @override
  String get graceMinutesHint =>
      'Minutes after the booked time, e.g. 30 is half an hour. If the car has not come by then, the booking becomes a no-show. Leave empty to switch this off.';

  @override
  String get graceMinutesInvalid => 'Enter 5 to 720 minutes, or leave it empty';

  @override
  String checkedInWithBooking(String reference, String time) {
    return '$reference checked in and linked to its $time booking';
  }

  @override
  String get manageServiceCategoriesHint => 'Add, rename or switch off service categories';

  @override
  String get manageVehicleSizesHint => 'The sizes prices depend on, such as sedan and SUV';

  @override
  String get clockInToStart => 'Clock in to start work';

  @override
  String get clockInToStartHint => 'The sections appear once you press «Clock in» above.';

  @override
  String get endOfDayQuestion => 'Has your day ended?';

  @override
  String get endOfDayHint => 'You are still clocked in. Signing out alone does not clock you out.';

  @override
  String get signOutOnly => 'Sign out only';

  @override
  String get clockOutAndSignOut => 'Clock out and sign out';

  @override
  String get requiresAttendanceField => 'Must clock in before working';

  @override
  String get requiresAttendanceHint => 'This role sees the app sections only after clocking in';

  @override
  String get sharedDeviceField => 'Shared device';

  @override
  String get sharedDeviceHint => 'Turn on for a device several staff use, to switch users on it by PIN';

  @override
  String get sharedDeviceAllBranches => 'Switching users is on for staff of every branch';

  @override
  String sharedDeviceBranch(String branch) {
    return 'Switching users is on for staff of $branch';
  }

  @override
  String get sharedDeviceWhichBranch => 'Staff of which branch use this device?';

  @override
  String get dailyUsageTab => 'Daily usage';

  @override
  String get issueMaterials => 'Issue materials';

  @override
  String get movementIssue => 'Issued';

  @override
  String get issueNoteField => 'What for (optional)';

  @override
  String get issueNoteHint => 'e.g. today\'s supply';

  @override
  String get nothingInStock => 'Nothing is in stock at this branch. Record a purchase first.';

  @override
  String get noUsageThatDay => 'Nothing left the stock on this day';

  @override
  String usedByWashes(String value) {
    return 'Washes: $value';
  }

  @override
  String issuedByHand(String value) {
    return 'Issued: $value';
  }

  @override
  String get usageCostTotal => 'Cost of what was used';

  @override
  String get usageCostHint => 'An estimate at today\'s costs, already an expense when bought';

  @override
  String get issuesByHandSection => 'Issues';

  @override
  String supplierLabel(String value) {
    return 'Supplier: $value';
  }

  @override
  String get stockIssueSubtitle => 'Issue the day\'s materials to staff';

  @override
  String get receivedByField => 'Received by';

  @override
  String receivedByLabel(String name) {
    return 'Received by $name';
  }

  @override
  String availableQuantity(String value) {
    return 'In stock: $value';
  }

  @override
  String onlyInStock(String name, String quantity, String unit) {
    return 'Only $quantity $unit of $name is in stock';
  }

  @override
  String get chooseReceiver => 'Choose who receives them';

  @override
  String get materialsIssued => 'Materials issued';

  @override
  String get materialField => 'Material';

  @override
  String get chooseMaterialFirst => 'Choose the material';

  @override
  String get addOneMaterial => 'Add at least one material to the list';

  @override
  String issueListSection(int count) {
    return 'Materials to issue ($count)';
  }

  @override
  String get issueListEmpty => 'Choose a material and its quantity, then press «Add material».';

  @override
  String get movementReversal => 'Issue cancelled';

  @override
  String get cancelIssueTitle => 'Cancel issue';

  @override
  String cancelIssueConfirm(String what) {
    return 'Cancel issuing $what? The quantity goes back in stock, and the issue stays on record as cancelled.';
  }

  @override
  String issueCancelledBy(String name) {
    return 'Cancelled by $name';
  }

  @override
  String get movementCancellation => 'Purchase cancelled';

  @override
  String get cancelPurchase => 'Cancel purchase';

  @override
  String get cancelPurchaseConfirm =>
      'This purchase\'s quantities leave the stock and its expense is removed. The purchase stays listed as cancelled.';

  @override
  String get newSupplierButton => 'New supplier';

  @override
  String get sourcePurchase => 'Inventory purchase';

  @override
  String get sourcePayroll => 'Payroll';

  @override
  String get sourceMaintenance => 'Maintenance';

  @override
  String get materialsExpenseTitle => 'Are these materials for the stock?';

  @override
  String get materialsExpenseHint =>
      'Record them from Inventory → New purchase: the stock goes up and the expense is recorded for you. Recording them here does not raise the stock, and recording them in both counts them twice.';

  @override
  String get openInventory => 'Open inventory';

  @override
  String get cancelMaintenance => 'Cancel maintenance';

  @override
  String get cancelMaintenanceConfirm =>
      'Its expense, if any, is removed, the next maintenance date and the machine\'s status go back as they were, and the line stays on record as cancelled.';

  @override
  String get cancelPayrollPayment => 'Cancel payroll payment';

  @override
  String get cancelPayrollPaymentConfirm =>
      'This month\'s expense is removed and the payroll is a draft again, to review and pay again. If the money already reached the staff, this does not get it back.';

  @override
  String get newMaterialOption => '+ New material…';

  @override
  String get addToList => 'Add material';

  @override
  String purchaseListSection(int count) {
    return 'Materials bought ($count)';
  }

  @override
  String get purchaseListEmpty => 'Choose a material, enter its quantity and price, then press «Add material».';

  @override
  String get savePurchase => 'Save purchase';

  @override
  String get payBenefit => 'BenefitPay';
}
