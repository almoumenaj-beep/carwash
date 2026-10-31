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
  String get networkError =>
      'Cannot reach the server. Check your connection and try again.';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';
}
