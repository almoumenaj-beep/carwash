// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'المغسلة';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get signInSubtitle => 'سجّل الدخول إلى مغسلتك';

  @override
  String get loginField => 'البريد الإلكتروني أو رقم الجوال';

  @override
  String get passwordField => 'كلمة المرور';

  @override
  String get signInButton => 'دخول';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get switchUserWithPin => 'تبديل المستخدم برمز PIN';

  @override
  String get signInWithPassword => 'الدخول بكلمة المرور بدلاً من ذلك';

  @override
  String get pinTitle => 'من يعمل الآن؟';

  @override
  String get pinField => 'رمز PIN';

  @override
  String get pinSignInButton => 'متابعة';

  @override
  String get noStaffWithPin =>
      'لا يوجد موظف لديه رمز PIN على هذا الجهاز. سجّل الدخول بكلمة المرور ثم عيّن رمزك من ملفك.';

  @override
  String greeting(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get ownerBadge => 'المالك';

  @override
  String get rolesSection => 'الأدوار';

  @override
  String get branchesSection => 'الفروع';

  @override
  String get allBranches => 'كل الفروع';

  @override
  String get noBranches => 'لم تُحدَّد لك فروع بعد';

  @override
  String get permissionsSection => 'الصلاحيات';

  @override
  String permissionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صلاحية',
      many: '$count صلاحية',
      few: '$count صلاحيات',
      two: 'صلاحيتان',
      one: 'صلاحية واحدة',
      zero: 'لا توجد صلاحيات',
    );
    return '$_temp0';
  }

  @override
  String get switchUser => 'تبديل المستخدم';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get changeLanguage => 'English';

  @override
  String get setPin => 'تعيين رمز PIN';

  @override
  String get currentPasswordField => 'كلمة المرور الحالية';

  @override
  String get newPinField => 'رمز PIN الجديد (4–6 أرقام)';

  @override
  String get confirmPinField => 'تأكيد رمز PIN';

  @override
  String get pinMustBeDigits => 'استخدم من 4 إلى 6 أرقام';

  @override
  String get pinsDoNotMatch => 'رمزا PIN غير متطابقين';

  @override
  String get pinSaved => 'تم حفظ رمز PIN';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get networkError => 'تعذّر الاتصال بالخادم. تحقّق من الاتصال وحاول مرة أخرى.';

  @override
  String get unexpectedError => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get delete => 'حذف';

  @override
  String get listSeparator => '، ';

  @override
  String get rolesTitle => 'الأدوار';

  @override
  String get rolesSubtitle => 'الأدوار وصلاحياتها';

  @override
  String get staffTitle => 'الموظفون';

  @override
  String get staffSubtitle => 'الحسابات والأدوار والفروع';

  @override
  String get devicesTitle => 'الأجهزة';

  @override
  String get devicesSubtitle => 'الجوالات والأجهزة اللوحية المسجّلة';

  @override
  String get newRole => 'دور جديد';

  @override
  String get roleName => 'اسم الدور';

  @override
  String get allPermissions => 'كل الصلاحيات';

  @override
  String get ownerRoleLocked => 'دور المالك يملك كل الصلاحيات دائماً ولا يمكن تعديله.';

  @override
  String get readOnlyRole => 'يمكنك عرض الأدوار فقط دون تعديلها.';

  @override
  String staffCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موظف',
      many: '$count موظفاً',
      few: '$count موظفين',
      two: 'موظفان',
      one: 'موظف واحد',
      zero: 'لا يوجد موظفون',
    );
    return '$_temp0';
  }

  @override
  String get deleteRole => 'حذف الدور';

  @override
  String deleteRoleConfirm(String name) {
    return 'حذف الدور «$name»؟';
  }

  @override
  String get newStaff => 'إضافة موظف';

  @override
  String get staffName => 'الاسم';

  @override
  String get emailField => 'البريد الإلكتروني';

  @override
  String get phoneField => 'رقم الجوال';

  @override
  String get emailOrPhoneRequired => 'أدخل البريد الإلكتروني أو رقم الجوال';

  @override
  String get passwordKeepHint => 'اتركه فارغاً لإبقاء كلمة المرور الحالية';

  @override
  String get allBranchesSwitch => 'يعمل في كل الفروع';

  @override
  String get activeSwitch => 'الحساب مفعّل';

  @override
  String get inactive => 'موقوف';

  @override
  String get noDevices => 'لم يسجّل أي جهاز الدخول بعد';

  @override
  String get revokeDevice => 'إلغاء';

  @override
  String revokeDeviceConfirm(String name) {
    return 'تسجيل خروج «$name» ومنع تبديل المستخدم عليه؟';
  }

  @override
  String lastSignIn(String date) {
    return 'آخر دخول: $date';
  }

  @override
  String get revoked => 'ملغى';
}
