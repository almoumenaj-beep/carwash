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
