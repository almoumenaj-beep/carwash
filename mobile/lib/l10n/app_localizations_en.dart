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
  String get chooseSizeForPrices => 'Choose the car\'s size to see prices.';

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
}
