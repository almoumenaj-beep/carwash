import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CarWash'**
  String get appTitle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your car wash'**
  String get signInSubtitle;

  /// No description provided for @loginField.
  ///
  /// In en, this message translates to:
  /// **'Email or phone'**
  String get loginField;

  /// No description provided for @passwordField.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordField;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @switchUserWithPin.
  ///
  /// In en, this message translates to:
  /// **'Switch user with PIN'**
  String get switchUserWithPin;

  /// No description provided for @signInWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password instead'**
  String get signInWithPassword;

  /// No description provided for @pinTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is working now?'**
  String get pinTitle;

  /// No description provided for @pinField.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinField;

  /// No description provided for @pinSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get pinSignInButton;

  /// No description provided for @noStaffWithPin.
  ///
  /// In en, this message translates to:
  /// **'Nobody on this device has a PIN yet. Sign in with a password and set one from your profile.'**
  String get noStaffWithPin;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greeting(String name);

  /// No description provided for @ownerBadge.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerBadge;

  /// No description provided for @rolesSection.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get rolesSection;

  /// No description provided for @branchesSection.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesSection;

  /// No description provided for @allBranches.
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get allBranches;

  /// No description provided for @noBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches assigned yet'**
  String get noBranches;

  /// No description provided for @permissionsSection.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsSection;

  /// No description provided for @permissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No permissions} =1{1 permission} other{{count} permissions}}'**
  String permissionsCount(int count);

  /// No description provided for @switchUser.
  ///
  /// In en, this message translates to:
  /// **'Switch user'**
  String get switchUser;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get changeLanguage;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @currentPasswordField.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordField;

  /// No description provided for @newPinField.
  ///
  /// In en, this message translates to:
  /// **'New PIN (4–6 digits)'**
  String get newPinField;

  /// No description provided for @confirmPinField.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPinField;

  /// No description provided for @pinMustBeDigits.
  ///
  /// In en, this message translates to:
  /// **'Use 4 to 6 digits'**
  String get pinMustBeDigits;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @pinSaved.
  ///
  /// In en, this message translates to:
  /// **'PIN saved'**
  String get pinSaved;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unexpectedError;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @rolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get rolesTitle;

  /// No description provided for @rolesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Roles and their permissions'**
  String get rolesSubtitle;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffTitle;

  /// No description provided for @staffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts, roles and branches'**
  String get staffSubtitle;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devicesTitle;

  /// No description provided for @devicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Phones and tablets signed in'**
  String get devicesSubtitle;

  /// No description provided for @newRole.
  ///
  /// In en, this message translates to:
  /// **'New role'**
  String get newRole;

  /// No description provided for @roleName.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get roleName;

  /// No description provided for @allPermissions.
  ///
  /// In en, this message translates to:
  /// **'All permissions'**
  String get allPermissions;

  /// No description provided for @ownerRoleLocked.
  ///
  /// In en, this message translates to:
  /// **'The owner role always has every permission and cannot be changed.'**
  String get ownerRoleLocked;

  /// No description provided for @readOnlyRole.
  ///
  /// In en, this message translates to:
  /// **'You can view roles but not change them.'**
  String get readOnlyRole;

  /// No description provided for @staffCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No staff} =1{1 staff member} other{{count} staff}}'**
  String staffCount(int count);

  /// No description provided for @deleteRole.
  ///
  /// In en, this message translates to:
  /// **'Delete role'**
  String get deleteRole;

  /// No description provided for @deleteRoleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the role “{name}”?'**
  String deleteRoleConfirm(String name);

  /// No description provided for @newStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get newStaff;

  /// No description provided for @staffName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get staffName;

  /// No description provided for @emailField.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailField;

  /// No description provided for @phoneField.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneField;

  /// No description provided for @emailOrPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an email or a phone number'**
  String get emailOrPhoneRequired;

  /// No description provided for @passwordKeepHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep the current password'**
  String get passwordKeepHint;

  /// No description provided for @allBranchesSwitch.
  ///
  /// In en, this message translates to:
  /// **'Works in all branches'**
  String get allBranchesSwitch;

  /// No description provided for @activeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Account active'**
  String get activeSwitch;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get inactive;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices have signed in yet'**
  String get noDevices;

  /// No description provided for @revokeDevice.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeDevice;

  /// No description provided for @revokeDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out “{name}” and stop PIN switching on it?'**
  String revokeDeviceConfirm(String name);

  /// No description provided for @lastSignIn.
  ///
  /// In en, this message translates to:
  /// **'Last sign-in: {date}'**
  String lastSignIn(String date);

  /// No description provided for @revoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get revoked;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Car wash settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, VAT, language and time zone'**
  String get settingsSubtitle;

  /// No description provided for @carWashName.
  ///
  /// In en, this message translates to:
  /// **'Car wash name'**
  String get carWashName;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @currencyLocked.
  ///
  /// In en, this message translates to:
  /// **'Set when the account was opened; it cannot be changed'**
  String get currencyLocked;

  /// No description provided for @currencyDecimals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no decimals} =1{1 decimal place} other{{count} decimal places}}'**
  String currencyDecimals(int count);

  /// No description provided for @vatSection.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatSection;

  /// No description provided for @vatRate.
  ///
  /// In en, this message translates to:
  /// **'VAT rate'**
  String get vatRate;

  /// No description provided for @vatRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate between 0 and 100'**
  String get vatRateInvalid;

  /// No description provided for @pricesIncludeVat.
  ///
  /// In en, this message translates to:
  /// **'Prices include VAT'**
  String get pricesIncludeVat;

  /// No description provided for @vatNumber.
  ///
  /// In en, this message translates to:
  /// **'VAT registration number'**
  String get vatNumber;

  /// No description provided for @languageField.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageField;

  /// No description provided for @timezoneField.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timezoneField;

  /// No description provided for @arabicLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabicLanguage;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @branchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesTitle;

  /// No description provided for @branchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Branches, opening hours and bays'**
  String get branchesSubtitle;

  /// No description provided for @newBranch.
  ///
  /// In en, this message translates to:
  /// **'New branch'**
  String get newBranch;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @branchCode.
  ///
  /// In en, this message translates to:
  /// **'Branch code'**
  String get branchCode;

  /// No description provided for @branchCodeHint.
  ///
  /// In en, this message translates to:
  /// **'A short code, e.g. MAIN or RIF-1'**
  String get branchCodeHint;

  /// No description provided for @addressField.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressField;

  /// No description provided for @branchActive.
  ///
  /// In en, this message translates to:
  /// **'Branch is open for business'**
  String get branchActive;

  /// No description provided for @branchClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get branchClosed;

  /// No description provided for @openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get openingHours;

  /// No description provided for @closedDay.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedDay;

  /// No description provided for @opensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get opensAt;

  /// No description provided for @closesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get closesAt;

  /// No description provided for @baysSection.
  ///
  /// In en, this message translates to:
  /// **'Bays'**
  String get baysSection;

  /// No description provided for @addBay.
  ///
  /// In en, this message translates to:
  /// **'Add bay'**
  String get addBay;

  /// No description provided for @bayName.
  ///
  /// In en, this message translates to:
  /// **'Bay name'**
  String get bayName;

  /// No description provided for @noBays.
  ///
  /// In en, this message translates to:
  /// **'No bays yet. Add the wash bays or stations of this branch.'**
  String get noBays;

  /// No description provided for @bayOutOfService.
  ///
  /// In en, this message translates to:
  /// **'Out of service'**
  String get bayOutOfService;

  /// No description provided for @deleteBranch.
  ///
  /// In en, this message translates to:
  /// **'Delete branch'**
  String get deleteBranch;

  /// No description provided for @deleteBranchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}” permanently? This is only possible for a branch that was never used; otherwise, close it instead.'**
  String deleteBranchConfirm(String name);

  /// No description provided for @branchDeleted.
  ///
  /// In en, this message translates to:
  /// **'Branch deleted'**
  String get branchDeleted;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get accountTitle;

  /// No description provided for @noSectionsYet.
  ///
  /// In en, this message translates to:
  /// **'Your role has no sections yet. Ask the owner to give you the permissions you need.'**
  String get noSectionsYet;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customers and their cars'**
  String get customersSubtitle;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @customerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or plate'**
  String get customerSearchHint;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomers;

  /// No description provided for @noCustomerMatches.
  ///
  /// In en, this message translates to:
  /// **'No customer matches. Register them as a new customer.'**
  String get noCustomerMatches;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerName;

  /// No description provided for @notesField.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesField;

  /// No description provided for @marketingConsent.
  ///
  /// In en, this message translates to:
  /// **'Agrees to receive offers and messages'**
  String get marketingConsent;

  /// No description provided for @marketingConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the customer; marketing messages are sent only with their consent'**
  String get marketingConsentHint;

  /// No description provided for @vehiclesSection.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get vehiclesSection;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add car'**
  String get addVehicle;

  /// No description provided for @noVehicles.
  ///
  /// In en, this message translates to:
  /// **'No cars yet'**
  String get noVehicles;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get plateNumber;

  /// No description provided for @vehicleSize.
  ///
  /// In en, this message translates to:
  /// **'Vehicle size'**
  String get vehicleSize;

  /// No description provided for @sizeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Size not set'**
  String get sizeUnknown;

  /// No description provided for @vehicleMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get vehicleMake;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehicleModel;

  /// No description provided for @vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get vehicleColor;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Services & prices'**
  String get catalogTitle;

  /// No description provided for @catalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Services, add-ons, vehicle sizes and prices'**
  String get catalogSubtitle;

  /// No description provided for @newService.
  ///
  /// In en, this message translates to:
  /// **'New service'**
  String get newService;

  /// No description provided for @noServices.
  ///
  /// In en, this message translates to:
  /// **'No services yet. Add your services and their prices.'**
  String get noServices;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get serviceName;

  /// No description provided for @categoryField.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryField;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'Uncategorised'**
  String get noCategory;

  /// No description provided for @durationField.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationField;

  /// No description provided for @descriptionField.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionField;

  /// No description provided for @isAddon.
  ///
  /// In en, this message translates to:
  /// **'Add-on (sold with a main service)'**
  String get isAddon;

  /// No description provided for @serviceActive.
  ///
  /// In en, this message translates to:
  /// **'Available for sale'**
  String get serviceActive;

  /// No description provided for @pricesSection.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get pricesSection;

  /// No description provided for @pricesIncludeVatHint.
  ///
  /// In en, this message translates to:
  /// **'Prices charged to the customer, VAT included'**
  String get pricesIncludeVatHint;

  /// No description provided for @pricesExcludeVatHint.
  ///
  /// In en, this message translates to:
  /// **'Prices before VAT'**
  String get pricesExcludeVatHint;

  /// No description provided for @samePriceAllSizes.
  ///
  /// In en, this message translates to:
  /// **'Same price for every vehicle size'**
  String get samePriceAllSizes;

  /// No description provided for @priceAllSizes.
  ///
  /// In en, this message translates to:
  /// **'Price (every size)'**
  String get priceAllSizes;

  /// No description provided for @branchPricesFor.
  ///
  /// In en, this message translates to:
  /// **'Prices at {branch}'**
  String branchPricesFor(String branch);

  /// No description provided for @branchPricesHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the general price'**
  String get branchPricesHint;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount like {example}'**
  String amountInvalid(String example);

  /// No description provided for @addonsSection.
  ///
  /// In en, this message translates to:
  /// **'Add-ons'**
  String get addonsSection;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'from {price}'**
  String fromPrice(String price);

  /// No description provided for @unpriced.
  ///
  /// In en, this message translates to:
  /// **'No price'**
  String get unpriced;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @inactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveLabel;

  /// No description provided for @sizesTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle sizes'**
  String get sizesTitle;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Service categories'**
  String get categoriesTitle;

  /// No description provided for @addSize.
  ///
  /// In en, this message translates to:
  /// **'Add size'**
  String get addSize;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @nameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameField;

  /// No description provided for @servicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No services} =1{1 service} other{{count} services}}'**
  String servicesCount(int count);

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteEntryConfirm(String name);

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFri;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @queueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check cars in and follow them through the wash'**
  String get queueSubtitle;

  /// No description provided for @queueTabWashing.
  ///
  /// In en, this message translates to:
  /// **'Washing'**
  String get queueTabWashing;

  /// No description provided for @queueTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get queueTabToday;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cars here.'**
  String get queueEmpty;

  /// No description provided for @noBranchAssigned.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to a branch yet.'**
  String get noBranchAssigned;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusWaiting;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'Washing'**
  String get statusInProgress;

  /// No description provided for @statusQualityCheck.
  ///
  /// In en, this message translates to:
  /// **'Quality check'**
  String get statusQualityCheck;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start washing'**
  String get actionStart;

  /// No description provided for @actionQualityCheck.
  ///
  /// In en, this message translates to:
  /// **'To quality check'**
  String get actionQualityCheck;

  /// No description provided for @actionReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get actionReady;

  /// No description provided for @actionDeliver.
  ///
  /// In en, this message translates to:
  /// **'Hand over'**
  String get actionDeliver;

  /// No description provided for @actionBackToWaiting.
  ///
  /// In en, this message translates to:
  /// **'Back to waiting'**
  String get actionBackToWaiting;

  /// No description provided for @actionBackToWashing.
  ///
  /// In en, this message translates to:
  /// **'Wash again'**
  String get actionBackToWashing;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelReasonField.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancelling'**
  String get cancelReasonField;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keepOrder;

  /// No description provided for @elapsedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{just now} other{{count} min}}'**
  String elapsedMinutes(int count);

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkIn;

  /// No description provided for @checkInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in a car'**
  String get checkInTitle;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkIn;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'{reference} checked in'**
  String checkedIn(String reference);

  /// No description provided for @matchingCars.
  ///
  /// In en, this message translates to:
  /// **'Registered cars'**
  String get matchingCars;

  /// No description provided for @shiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get shiftTitle;

  /// No description provided for @shiftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the cashier, count and match the cash at close'**
  String get shiftSubtitle;

  /// No description provided for @noOpenShift.
  ///
  /// In en, this message translates to:
  /// **'The cashier is not open. Count the cash in the drawer to open it.'**
  String get noOpenShift;

  /// No description provided for @openingFloatField.
  ///
  /// In en, this message translates to:
  /// **'Cash in the drawer at opening'**
  String get openingFloatField;

  /// No description provided for @openingFloatHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if the drawer is empty.'**
  String get openingFloatHint;

  /// No description provided for @openShift.
  ///
  /// In en, this message translates to:
  /// **'Open cashier'**
  String get openShift;

  /// No description provided for @shiftOpenSince.
  ///
  /// In en, this message translates to:
  /// **'Open since {time}'**
  String shiftOpenSince(String time);

  /// No description provided for @shiftInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get shiftInvoices;

  /// No description provided for @shiftCashTaken.
  ///
  /// In en, this message translates to:
  /// **'Cash taken'**
  String get shiftCashTaken;

  /// No description provided for @shiftDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts given'**
  String get shiftDiscounts;

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected in the drawer'**
  String get expectedCash;

  /// No description provided for @closeShift.
  ///
  /// In en, this message translates to:
  /// **'Close cashier'**
  String get closeShift;

  /// No description provided for @countedCashField.
  ///
  /// In en, this message translates to:
  /// **'Cash counted in the drawer'**
  String get countedCashField;

  /// No description provided for @drawerMatches.
  ///
  /// In en, this message translates to:
  /// **'The drawer matches'**
  String get drawerMatches;

  /// No description provided for @drawerShort.
  ///
  /// In en, this message translates to:
  /// **'Short by {amount}'**
  String drawerShort(String amount);

  /// No description provided for @drawerOver.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String drawerOver(String amount);

  /// No description provided for @varianceNoteField.
  ///
  /// In en, this message translates to:
  /// **'Why does it not match?'**
  String get varianceNoteField;

  /// No description provided for @varianceLabel.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get varianceLabel;

  /// No description provided for @shiftClosed.
  ///
  /// In en, this message translates to:
  /// **'Cashier closed'**
  String get shiftClosed;

  /// No description provided for @openShiftFirst.
  ///
  /// In en, this message translates to:
  /// **'Open the cashier to take payment.'**
  String get openShiftFirst;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get checkoutTitle;

  /// No description provided for @collectPayment.
  ///
  /// In en, this message translates to:
  /// **'Collect payment'**
  String get collectPayment;

  /// No description provided for @payOnly.
  ///
  /// In en, this message translates to:
  /// **'Pay only'**
  String get payOnly;

  /// No description provided for @payAndDeliver.
  ///
  /// In en, this message translates to:
  /// **'Pay and hand over'**
  String get payAndDeliver;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get subtotalLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @vatIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'Includes VAT {rate}%'**
  String vatIncludedLabel(String rate);

  /// No description provided for @vatAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT {rate}%'**
  String vatAddedLabel(String rate);

  /// No description provided for @discountLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Your limit: {limit}%'**
  String discountLimitHint(String limit);

  /// No description provided for @discountOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Above your limit of {limit}%'**
  String discountOverLimit(String limit);

  /// No description provided for @discountReasonField.
  ///
  /// In en, this message translates to:
  /// **'Reason for the discount'**
  String get discountReasonField;

  /// No description provided for @cashReceivedField.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get cashReceivedField;

  /// No description provided for @cashTooLittle.
  ///
  /// In en, this message translates to:
  /// **'Less than the total'**
  String get cashTooLittle;

  /// No description provided for @changeDue.
  ///
  /// In en, this message translates to:
  /// **'Change: {amount}'**
  String changeDue(String amount);

  /// No description provided for @paidTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidTitle;

  /// No description provided for @paidBadge.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidBadge;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get darkMode;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @inventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Materials, stock, purchases and counts'**
  String get inventorySubtitle;

  /// No description provided for @stockTab.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockTab;

  /// No description provided for @purchasesTab.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchasesTab;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New purchase'**
  String get newPurchase;

  /// No description provided for @addMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add material'**
  String get addMaterial;

  /// No description provided for @noMaterials.
  ///
  /// In en, this message translates to:
  /// **'No materials yet. Add the materials you use, such as shampoo or towels.'**
  String get noMaterials;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low: minimum {min} {unit}'**
  String lowStock(String min, String unit);

  /// No description provided for @minStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum {min} {unit}'**
  String minStockLabel(String min, String unit);

  /// No description provided for @unitCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Last cost {cost} per {unit}'**
  String unitCostLabel(String cost, String unit);

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'Stock count'**
  String get stockCount;

  /// No description provided for @countedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity counted'**
  String get countedQuantity;

  /// No description provided for @stockHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get stockHistory;

  /// No description provided for @noMovements.
  ///
  /// In en, this message translates to:
  /// **'No movements yet.'**
  String get noMovements;

  /// No description provided for @movementPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get movementPurchase;

  /// No description provided for @movementConsumption.
  ///
  /// In en, this message translates to:
  /// **'Used by a wash'**
  String get movementConsumption;

  /// No description provided for @movementCount.
  ///
  /// In en, this message translates to:
  /// **'Stock count'**
  String get movementCount;

  /// No description provided for @quantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity, e.g. 2.5'**
  String get quantityInvalid;

  /// No description provided for @unitField.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitField;

  /// No description provided for @unitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. L, kg, pc'**
  String get unitHint;

  /// No description provided for @minStockField.
  ///
  /// In en, this message translates to:
  /// **'Minimum stock'**
  String get minStockField;

  /// No description provided for @minStockHint.
  ///
  /// In en, this message translates to:
  /// **'You are warned when stock falls to this level.'**
  String get minStockHint;

  /// No description provided for @noPurchases.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet.'**
  String get noPurchases;

  /// No description provided for @materialsSection.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsSection;

  /// No description provided for @addMaterialLine.
  ///
  /// In en, this message translates to:
  /// **'Add material'**
  String get addMaterialLine;

  /// No description provided for @quantityField.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityField;

  /// No description provided for @unitPriceField.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get unitPriceField;

  /// No description provided for @addAtLeastOneMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add at least one material.'**
  String get addAtLeastOneMaterial;

  /// No description provided for @purchaseCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'The purchase is also recorded as an expense in this category.'**
  String get purchaseCategoryHint;

  /// No description provided for @serviceMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials used'**
  String get serviceMaterials;

  /// No description provided for @serviceMaterialsHint.
  ///
  /// In en, this message translates to:
  /// **'What one sale of this service uses. It is taken from the branch\'s stock when the wash starts.'**
  String get serviceMaterialsHint;

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @expensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spending, suppliers and recurring bills'**
  String get expensesSubtitle;

  /// No description provided for @owedTab.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get owedTab;

  /// No description provided for @suppliersTab.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTab;

  /// No description provided for @recurringTab.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTab;

  /// No description provided for @newExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get newExpense;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get expenseCategories;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategory;

  /// No description provided for @amountField.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountField;

  /// No description provided for @paymentMethodField.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paymentMethodField;

  /// No description provided for @payFromDrawer.
  ///
  /// In en, this message translates to:
  /// **'From the drawer'**
  String get payFromDrawer;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @payBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get payBankTransfer;

  /// No description provided for @payCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payCard;

  /// No description provided for @notPaidYet.
  ///
  /// In en, this message translates to:
  /// **'Not paid yet'**
  String get notPaidYet;

  /// No description provided for @payFromDrawerHint.
  ///
  /// In en, this message translates to:
  /// **'Taken from the cashier drawer today; the count at close expects it.'**
  String get payFromDrawerHint;

  /// No description provided for @supplierField.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierField;

  /// No description provided for @noSupplier.
  ///
  /// In en, this message translates to:
  /// **'No supplier'**
  String get noSupplier;

  /// No description provided for @owedToSupplierHint.
  ///
  /// In en, this message translates to:
  /// **'Recorded as owed to this supplier until paid.'**
  String get owedToSupplierHint;

  /// No description provided for @expenseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseDate;

  /// No description provided for @payExpense.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payExpense;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @totalOwed.
  ///
  /// In en, this message translates to:
  /// **'Total owed'**
  String get totalOwed;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalSpent;

  /// No description provided for @nothingOwed.
  ///
  /// In en, this message translates to:
  /// **'Nothing is owed.'**
  String get nothingOwed;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get noExpenses;

  /// No description provided for @recurringBadge.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringBadge;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get addSupplier;

  /// No description provided for @noSuppliers.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet.'**
  String get noSuppliers;

  /// No description provided for @owedAmount.
  ///
  /// In en, this message translates to:
  /// **'Owed {amount}'**
  String owedAmount(String amount);

  /// No description provided for @addRecurring.
  ///
  /// In en, this message translates to:
  /// **'Add recurring expense'**
  String get addRecurring;

  /// No description provided for @recurringHint.
  ///
  /// In en, this message translates to:
  /// **'On its due date a recurring expense is recorded as owed, until it is paid.'**
  String get recurringHint;

  /// No description provided for @noRecurring.
  ///
  /// In en, this message translates to:
  /// **'No recurring expenses.'**
  String get noRecurring;

  /// No description provided for @nextDue.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextDue(String date);

  /// No description provided for @nextDueField.
  ///
  /// In en, this message translates to:
  /// **'Next due date'**
  String get nextDueField;

  /// No description provided for @recurringDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shop rent'**
  String get recurringDescriptionHint;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// No description provided for @frequencyYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get frequencyYearly;

  /// No description provided for @cashPaidOut.
  ///
  /// In en, this message translates to:
  /// **'Expenses paid from the drawer'**
  String get cashPaidOut;

  /// No description provided for @expensesTotal.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTotal;

  /// No description provided for @netTotal.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netTotal;

  /// No description provided for @dailySalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily sales'**
  String get dailySalesTitle;

  /// No description provided for @dailySalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales, cars and staff for any day'**
  String get dailySalesSubtitle;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @noSalesThatDay.
  ///
  /// In en, this message translates to:
  /// **'No sales or cars on this day.'**
  String get noSalesThatDay;

  /// No description provided for @salesTotal.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesTotal;

  /// No description provided for @averageTicket.
  ///
  /// In en, this message translates to:
  /// **'Average invoice'**
  String get averageTicket;

  /// No description provided for @vatTotal.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatTotal;

  /// No description provided for @carsCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Cars checked in'**
  String get carsCheckedIn;

  /// No description provided for @carsInQueue.
  ///
  /// In en, this message translates to:
  /// **'Still in the queue'**
  String get carsInQueue;

  /// No description provided for @byCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashiers'**
  String get byCashier;

  /// No description provided for @byHour.
  ///
  /// In en, this message translates to:
  /// **'Sales by hour'**
  String get byHour;

  /// No description provided for @invoicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice} other{{count} invoices}}'**
  String invoicesCount(int count);

  /// No description provided for @carsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 car} other{{count} cars}}'**
  String carsCount(int count);

  /// No description provided for @chooseWasher.
  ///
  /// In en, this message translates to:
  /// **'Choose the washer who will wash the car.'**
  String get chooseWasher;

  /// No description provided for @noWashersInBranch.
  ///
  /// In en, this message translates to:
  /// **'No staff work at this branch yet; add them under Staff.'**
  String get noWashersInBranch;

  /// No description provided for @isPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get isPackage;

  /// No description provided for @isPackageHint.
  ///
  /// In en, this message translates to:
  /// **'Bundles existing services at a discount'**
  String get isPackageHint;

  /// No description provided for @packagesSection.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packagesSection;

  /// No description provided for @packageServicesSection.
  ///
  /// In en, this message translates to:
  /// **'Services in the package'**
  String get packageServicesSection;

  /// No description provided for @packageNeedsTwoServices.
  ///
  /// In en, this message translates to:
  /// **'Choose at least two services'**
  String get packageNeedsTwoServices;

  /// No description provided for @packageDiscountSection.
  ///
  /// In en, this message translates to:
  /// **'Package discount'**
  String get packageDiscountSection;

  /// No description provided for @discountPercent.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get discountPercent;

  /// No description provided for @packageDiscountField.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get packageDiscountField;

  /// No description provided for @packagePricesSection.
  ///
  /// In en, this message translates to:
  /// **'Price per size'**
  String get packagePricesSection;

  /// No description provided for @discountOff.
  ///
  /// In en, this message translates to:
  /// **'{discount} off'**
  String discountOff(String discount);

  /// No description provided for @packageSaves.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount}'**
  String packageSaves(String amount);

  /// No description provided for @inspectionHint.
  ///
  /// In en, this message translates to:
  /// **'Tick each service that was done properly'**
  String get inspectionHint;

  /// No description provided for @passInspection.
  ///
  /// In en, this message translates to:
  /// **'Passed – ready'**
  String get passInspection;

  /// No description provided for @inspectionPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed the check'**
  String get inspectionPassed;

  /// No description provided for @inspectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Sent back for rework'**
  String get inspectionFailed;

  /// No description provided for @staffPinField.
  ///
  /// In en, this message translates to:
  /// **'PIN (4–6 digits)'**
  String get staffPinField;

  /// No description provided for @staffPinHint.
  ///
  /// In en, this message translates to:
  /// **'Lets them switch in on a shared device from “Switch user”'**
  String get staffPinHint;

  /// No description provided for @staffPinKeepHint.
  ///
  /// In en, this message translates to:
  /// **'Has a PIN; leave empty to keep it'**
  String get staffPinKeepHint;

  /// No description provided for @maxDiscountField.
  ///
  /// In en, this message translates to:
  /// **'Largest discount'**
  String get maxDiscountField;

  /// No description provided for @maxDiscountHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {limit}% (your own limit)'**
  String maxDiscountHint(String limit);

  /// No description provided for @percentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a percentage from 0 to 100'**
  String get percentInvalid;

  /// No description provided for @registerWalkInHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: the customer and car are saved with it'**
  String get registerWalkInHint;

  /// No description provided for @servicesSection.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesSection;

  /// No description provided for @chooseSizeForPrices.
  ///
  /// In en, this message translates to:
  /// **'Services, packages and add-ons show with their prices for that size.'**
  String get chooseSizeForPrices;

  /// No description provided for @chooseMainService.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one main service.'**
  String get chooseMainService;

  /// No description provided for @bayField.
  ///
  /// In en, this message translates to:
  /// **'Bay'**
  String get bayField;

  /// No description provided for @noBayYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get noBayYet;

  /// No description provided for @washersSection.
  ///
  /// In en, this message translates to:
  /// **'Washers'**
  String get washersSection;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// No description provided for @aboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'about {count} min'**
  String aboutMinutes(int count);

  /// No description provided for @checkedInBy.
  ///
  /// In en, this message translates to:
  /// **'Checked in by {name}'**
  String checkedInBy(String name);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @assignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Bay, washers and notes'**
  String get assignmentTitle;

  /// No description provided for @cancelledBecause.
  ///
  /// In en, this message translates to:
  /// **'Cancelled: {reason}'**
  String cancelledBecause(String reason);

  /// No description provided for @clockInAt.
  ///
  /// In en, this message translates to:
  /// **'Clock in at'**
  String get clockInAt;

  /// No description provided for @notClockedIn.
  ///
  /// In en, this message translates to:
  /// **'You have not clocked in'**
  String get notClockedIn;

  /// No description provided for @clockedInSince.
  ///
  /// In en, this message translates to:
  /// **'At work since {time}'**
  String clockedInSince(String time);

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock out'**
  String get clockOut;

  /// No description provided for @staffAffairsTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff affairs'**
  String get staffAffairsTitle;

  /// No description provided for @staffAffairsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay, commission, attendance and payroll'**
  String get staffAffairsSubtitle;

  /// No description provided for @employeesTab.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeesTab;

  /// No description provided for @attendanceTab.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTab;

  /// No description provided for @payrollTab.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payrollTab;

  /// No description provided for @noCommission.
  ///
  /// In en, this message translates to:
  /// **'No commission'**
  String get noCommission;

  /// No description provided for @commissionPerCar.
  ///
  /// In en, this message translates to:
  /// **'{amount} per car'**
  String commissionPerCar(String amount);

  /// No description provided for @commissionPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of each car'**
  String commissionPercent(String percent);

  /// No description provided for @salaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary {amount}'**
  String salaryLabel(String amount);

  /// No description provided for @monthlySalaryField.
  ///
  /// In en, this message translates to:
  /// **'Monthly salary'**
  String get monthlySalaryField;

  /// No description provided for @commissionField.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commissionField;

  /// No description provided for @noCommissionShort.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noCommissionShort;

  /// No description provided for @perCarShort.
  ///
  /// In en, this message translates to:
  /// **'Per car'**
  String get perCarShort;

  /// No description provided for @perCarField.
  ///
  /// In en, this message translates to:
  /// **'Amount per car'**
  String get perCarField;

  /// No description provided for @percentOfCarField.
  ///
  /// In en, this message translates to:
  /// **'Share of the car\'s value'**
  String get percentOfCarField;

  /// No description provided for @commissionSplitHint.
  ///
  /// In en, this message translates to:
  /// **'Split equally when several washers share a car'**
  String get commissionSplitHint;

  /// No description provided for @noAttendance.
  ///
  /// In en, this message translates to:
  /// **'No one clocked in on this day'**
  String get noAttendance;

  /// No description provided for @stillAtWork.
  ///
  /// In en, this message translates to:
  /// **'Since {time}, still at work'**
  String stillAtWork(String time);

  /// No description provided for @hoursWorked.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String hoursWorked(String hours);

  /// No description provided for @calculateThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Calculate this month'**
  String get calculateThisMonth;

  /// No description provided for @calculateLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get calculateLastMonth;

  /// No description provided for @noPayroll.
  ///
  /// In en, this message translates to:
  /// **'No payroll yet'**
  String get noPayroll;

  /// No description provided for @payrollPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payrollPaid;

  /// No description provided for @payrollDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft, recalculated until paid'**
  String get payrollDraft;

  /// No description provided for @commissionAmount.
  ///
  /// In en, this message translates to:
  /// **'Commission {amount}'**
  String commissionAmount(String amount);

  /// No description provided for @payPayroll.
  ///
  /// In en, this message translates to:
  /// **'Pay payroll'**
  String get payPayroll;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @branchField.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branchField;

  /// No description provided for @equipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Equipment and maintenance'**
  String get equipmentTitle;

  /// No description provided for @equipmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Machines, maintenance due and breakdowns'**
  String get equipmentSubtitle;

  /// No description provided for @addEquipment.
  ///
  /// In en, this message translates to:
  /// **'Add equipment'**
  String get addEquipment;

  /// No description provided for @editEquipment.
  ///
  /// In en, this message translates to:
  /// **'Edit equipment'**
  String get editEquipment;

  /// No description provided for @noEquipment.
  ///
  /// In en, this message translates to:
  /// **'No equipment yet. Add pressure washers, vacuums and compressors to keep track of their maintenance.'**
  String get noEquipment;

  /// No description provided for @equipmentInService.
  ///
  /// In en, this message translates to:
  /// **'In service'**
  String get equipmentInService;

  /// No description provided for @equipmentOutOfService.
  ///
  /// In en, this message translates to:
  /// **'Broken'**
  String get equipmentOutOfService;

  /// No description provided for @equipmentRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get equipmentRetired;

  /// No description provided for @maintenanceOverdue.
  ///
  /// In en, this message translates to:
  /// **'Maintenance overdue by {count, plural, =1{1 day} other{{count} days}}'**
  String maintenanceOverdue(int count);

  /// No description provided for @maintenanceDueToday.
  ///
  /// In en, this message translates to:
  /// **'Maintenance due today'**
  String get maintenanceDueToday;

  /// No description provided for @maintenanceDueIn.
  ///
  /// In en, this message translates to:
  /// **'Maintenance in {count, plural, =1{1 day} other{{count} days}}'**
  String maintenanceDueIn(int count);

  /// No description provided for @maintenanceDueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 machine needs maintenance now} other{{count} machines need maintenance now}}'**
  String maintenanceDueCount(int count);

  /// No description provided for @reportBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Report a breakdown'**
  String get reportBreakdown;

  /// No description provided for @backInService.
  ///
  /// In en, this message translates to:
  /// **'Back in service'**
  String get backInService;

  /// No description provided for @retireEquipment.
  ///
  /// In en, this message translates to:
  /// **'Retire'**
  String get retireEquipment;

  /// No description provided for @recordMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Record maintenance'**
  String get recordMaintenance;

  /// No description provided for @noPeriodicMaintenance.
  ///
  /// In en, this message translates to:
  /// **'No periodic maintenance'**
  String get noPeriodicMaintenance;

  /// No description provided for @maintenanceEvery.
  ///
  /// In en, this message translates to:
  /// **'Maintenance every {count, plural, =1{day} other{{count} days}}'**
  String maintenanceEvery(int count);

  /// No description provided for @nextMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Next maintenance'**
  String get nextMaintenance;

  /// No description provided for @serialNumberField.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get serialNumberField;

  /// No description provided for @purchaseSection.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchaseSection;

  /// No description provided for @maintenanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Maintenance history'**
  String get maintenanceHistory;

  /// No description provided for @noMaintenanceYet.
  ///
  /// In en, this message translates to:
  /// **'No maintenance recorded'**
  String get noMaintenanceYet;

  /// No description provided for @periodicMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Periodic'**
  String get periodicMaintenance;

  /// No description provided for @repairMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get repairMaintenance;

  /// No description provided for @equipmentNameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get equipmentNameField;

  /// No description provided for @equipmentNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pressure washer 1'**
  String get equipmentNameHint;

  /// No description provided for @maintenanceIntervalField.
  ///
  /// In en, this message translates to:
  /// **'Periodic maintenance every'**
  String get maintenanceIntervalField;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @maintenanceIntervalHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if it needs no periodic maintenance'**
  String get maintenanceIntervalHint;

  /// No description provided for @maintenanceIntervalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 3650 days'**
  String get maintenanceIntervalInvalid;

  /// No description provided for @purchaseDateField.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get purchaseDateField;

  /// No description provided for @purchaseCostField.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get purchaseCostField;

  /// No description provided for @periodicMaintenanceHint.
  ///
  /// In en, this message translates to:
  /// **'The next maintenance is counted from this one'**
  String get periodicMaintenanceHint;

  /// No description provided for @repairMaintenanceHint.
  ///
  /// In en, this message translates to:
  /// **'A broken machine goes back in service'**
  String get repairMaintenanceHint;

  /// No description provided for @maintenanceDateField.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get maintenanceDateField;

  /// No description provided for @whatWasDoneField.
  ///
  /// In en, this message translates to:
  /// **'What was done?'**
  String get whatWasDoneField;

  /// No description provided for @maintenanceCostField.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get maintenanceCostField;

  /// No description provided for @maintenanceCostHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: recorded as an expense of the branch'**
  String get maintenanceCostHint;

  /// No description provided for @financialReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial reports'**
  String get financialReportsTitle;

  /// No description provided for @financialReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profit and loss, cash flow and profitability'**
  String get financialReportsSubtitle;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @customPeriod.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customPeriod;

  /// No description provided for @profitLossTab.
  ///
  /// In en, this message translates to:
  /// **'Profit & loss'**
  String get profitLossTab;

  /// No description provided for @cashFlowTab.
  ///
  /// In en, this message translates to:
  /// **'Cash flow'**
  String get cashFlowTab;

  /// No description provided for @profitabilityTab.
  ///
  /// In en, this message translates to:
  /// **'Profitability'**
  String get profitabilityTab;

  /// No description provided for @noFiguresInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No sales or expenses in this period'**
  String get noFiguresInPeriod;

  /// No description provided for @profitLabel.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get profitLabel;

  /// No description provided for @lossLabel.
  ///
  /// In en, this message translates to:
  /// **'Net loss'**
  String get lossLabel;

  /// No description provided for @marginLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin {percent}%'**
  String marginLabel(String percent);

  /// No description provided for @revenueSection.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueSection;

  /// No description provided for @grossSales.
  ///
  /// In en, this message translates to:
  /// **'Sales before discounts'**
  String get grossSales;

  /// No description provided for @netSales.
  ///
  /// In en, this message translates to:
  /// **'Net sales'**
  String get netSales;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get totalExpenses;

  /// No description provided for @ofWhichOwed.
  ///
  /// In en, this message translates to:
  /// **'Of which still owed'**
  String get ofWhichOwed;

  /// No description provided for @profitLossNote.
  ///
  /// In en, this message translates to:
  /// **'Net sales leave out VAT. Expenses count by their date, paid or owed: materials when bought, wages when payroll is paid.'**
  String get profitLossNote;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get moneyIn;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get moneyOut;

  /// No description provided for @netCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow'**
  String get netCashFlow;

  /// No description provided for @stillOwed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing owed} =1{1 bill still owed} other{{count} bills still owed}}'**
  String stillOwed(int count);

  /// No description provided for @byDay.
  ///
  /// In en, this message translates to:
  /// **'By day'**
  String get byDay;

  /// No description provided for @cashFlowNote.
  ///
  /// In en, this message translates to:
  /// **'Money in is what customers paid; money out is expenses actually paid, on the day paid. Owed is what is unpaid today.'**
  String get cashFlowNote;

  /// No description provided for @byBranch.
  ///
  /// In en, this message translates to:
  /// **'By branch'**
  String get byBranch;

  /// No description provided for @materialsCost.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsCost;

  /// No description provided for @serviceProfitNote.
  ///
  /// In en, this message translates to:
  /// **'Net sales after discounts and VAT, less an estimate of materials at today\'s costs.'**
  String get serviceProfitNote;

  /// No description provided for @payLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payLabel;

  /// No description provided for @washerProfitNote.
  ///
  /// In en, this message translates to:
  /// **'Each car\'s value is split between its washers; pay is salary and commission in the period\'s payrolls.'**
  String get washerProfitNote;

  /// No description provided for @appointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get appointmentsTitle;

  /// No description provided for @appointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Booked cars, checked in when they arrive'**
  String get appointmentsSubtitle;

  /// No description provided for @newBooking.
  ///
  /// In en, this message translates to:
  /// **'New booking'**
  String get newBooking;

  /// No description provided for @changeBooking.
  ///
  /// In en, this message translates to:
  /// **'Change booking'**
  String get changeBooking;

  /// No description provided for @checkInBooking.
  ///
  /// In en, this message translates to:
  /// **'Check in the booked car'**
  String get checkInBooking;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @bookedAt.
  ///
  /// In en, this message translates to:
  /// **'Booked for {time}'**
  String bookedAt(String time);

  /// No description provided for @bookingPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'To reach the customer; needed when the car is not registered'**
  String get bookingPhoneHint;

  /// No description provided for @bookingTimeSection.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get bookingTimeSection;

  /// No description provided for @chooseServicesForTimes.
  ///
  /// In en, this message translates to:
  /// **'Choose the services to see the free times.'**
  String get chooseServicesForTimes;

  /// No description provided for @noFreeTimes.
  ///
  /// In en, this message translates to:
  /// **'No free times on this day.'**
  String get noFreeTimes;

  /// No description provided for @appointmentBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get appointmentBooked;

  /// No description provided for @appointmentCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get appointmentCheckedIn;

  /// No description provided for @appointmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get appointmentCancelled;

  /// No description provided for @appointmentNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get appointmentNoShow;

  /// No description provided for @noBookingsThatDay.
  ///
  /// In en, this message translates to:
  /// **'No bookings on this day'**
  String get noBookingsThatDay;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @markNoShow.
  ///
  /// In en, this message translates to:
  /// **'Did not come'**
  String get markNoShow;

  /// No description provided for @openOrder.
  ///
  /// In en, this message translates to:
  /// **'Open the order'**
  String get openOrder;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @chooseSizeFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose the vehicle size first'**
  String get chooseSizeFirst;

  /// No description provided for @autoClockedOut.
  ///
  /// In en, this message translates to:
  /// **'clocked out automatically at closing'**
  String get autoClockedOut;

  /// No description provided for @groupDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get groupDaily;

  /// No description provided for @groupMore.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get groupMore;

  /// No description provided for @groupFinance.
  ///
  /// In en, this message translates to:
  /// **'Money and reports'**
  String get groupFinance;

  /// No description provided for @groupResources.
  ///
  /// In en, this message translates to:
  /// **'Stock and equipment'**
  String get groupResources;

  /// No description provided for @groupPeople.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get groupPeople;

  /// No description provided for @groupSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get groupSetup;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get manageCategories;

  /// No description provided for @manageCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Add, rename or switch off categories'**
  String get manageCategoriesHint;

  /// No description provided for @appointmentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get appointmentConfirmed;

  /// No description provided for @appointmentLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get appointmentLate;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @confirmBookingHint.
  ///
  /// In en, this message translates to:
  /// **'Once the customer says they are coming'**
  String get confirmBookingHint;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @graceMinutesField.
  ///
  /// In en, this message translates to:
  /// **'Grace time for late bookings'**
  String get graceMinutesField;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesUnit;

  /// No description provided for @graceMinutesHint.
  ///
  /// In en, this message translates to:
  /// **'If the car has not come this long after its time, the booking becomes a no-show. Leave empty to switch this off.'**
  String get graceMinutesHint;

  /// No description provided for @graceMinutesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 5 to 720 minutes, or leave it empty'**
  String get graceMinutesInvalid;

  /// No description provided for @checkedInWithBooking.
  ///
  /// In en, this message translates to:
  /// **'{reference} checked in and linked to its {time} booking'**
  String checkedInWithBooking(String reference, String time);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
