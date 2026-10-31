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
}
