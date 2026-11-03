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

  @override
  String get settingsTitle => 'إعدادات المغسلة';

  @override
  String get settingsSubtitle => 'الاسم والضريبة واللغة والمنطقة الزمنية';

  @override
  String get carWashName => 'اسم المغسلة';

  @override
  String get currency => 'العملة';

  @override
  String get currencyLocked => 'تُحدَّد عند فتح الحساب ولا يمكن تغييرها';

  @override
  String currencyDecimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منزلة عشرية',
      few: '$count منازل عشرية',
      two: 'منزلتان عشريتان',
      one: 'منزلة عشرية واحدة',
      zero: 'بدون كسور',
    );
    return '$_temp0';
  }

  @override
  String get vatSection => 'ضريبة القيمة المضافة';

  @override
  String get vatRate => 'نسبة الضريبة';

  @override
  String get vatRateInvalid => 'أدخل نسبة بين 0 و100';

  @override
  String get pricesIncludeVat => 'الأسعار شاملة الضريبة';

  @override
  String get vatNumber => 'الرقم الضريبي';

  @override
  String get languageField => 'اللغة';

  @override
  String get timezoneField => 'المنطقة الزمنية';

  @override
  String get arabicLanguage => 'العربية';

  @override
  String get englishLanguage => 'English';

  @override
  String get branchesTitle => 'الفروع';

  @override
  String get branchesSubtitle => 'الفروع وساعات العمل والأرصفة';

  @override
  String get newBranch => 'فرع جديد';

  @override
  String get branchName => 'اسم الفرع';

  @override
  String get branchCode => 'رمز الفرع';

  @override
  String get branchCodeHint => 'رمز قصير بالإنجليزية، مثل MAIN أو RIF-1';

  @override
  String get addressField => 'العنوان';

  @override
  String get branchActive => 'الفرع يعمل';

  @override
  String get branchClosed => 'متوقف';

  @override
  String get openingHours => 'ساعات العمل';

  @override
  String get closedDay => 'مغلق';

  @override
  String get opensAt => 'يفتح';

  @override
  String get closesAt => 'يغلق';

  @override
  String get baysSection => 'الأرصفة';

  @override
  String get addBay => 'إضافة رصيف';

  @override
  String get bayName => 'اسم الرصيف';

  @override
  String get noBays => 'لا توجد أرصفة بعد. أضف أماكن الغسيل في هذا الفرع.';

  @override
  String get bayOutOfService => 'خارج الخدمة';

  @override
  String get deleteBranch => 'حذف الفرع';

  @override
  String deleteBranchConfirm(String name) {
    return 'حذف «$name» نهائياً؟ يُسمح بذلك فقط لفرع لم يُستخدم بعد، وإلا فأوقفه بدلاً من حذفه.';
  }

  @override
  String get branchDeleted => 'تم حذف الفرع';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get noSectionsYet => 'لا توجد أقسام لدورك بعد. اطلب من المالك منحك الصلاحيات التي تحتاجها.';

  @override
  String get customersTitle => 'العملاء';

  @override
  String get customersSubtitle => 'العملاء وسياراتهم';

  @override
  String get newCustomer => 'عميل جديد';

  @override
  String get customerSearchHint => 'ابحث بالاسم أو الجوال أو رقم اللوحة';

  @override
  String get noCustomers => 'لا يوجد عملاء بعد';

  @override
  String get noCustomerMatches => 'لا يوجد عميل مطابق. سجّله كعميل جديد.';

  @override
  String get customerName => 'اسم العميل';

  @override
  String get notesField => 'ملاحظات';

  @override
  String get marketingConsent => 'يوافق على استلام العروض والرسائل';

  @override
  String get marketingConsentHint => 'اسأل العميل؛ لا تُرسل الرسائل التسويقية إلا بموافقته';

  @override
  String get vehiclesSection => 'السيارات';

  @override
  String get addVehicle => 'إضافة سيارة';

  @override
  String get noVehicles => 'لا توجد سيارات بعد';

  @override
  String get plateNumber => 'رقم اللوحة';

  @override
  String get vehicleSize => 'حجم السيارة';

  @override
  String get sizeUnknown => 'الحجم غير محدد';

  @override
  String get vehicleMake => 'الشركة المصنّعة';

  @override
  String get vehicleModel => 'الطراز';

  @override
  String get vehicleColor => 'اللون';

  @override
  String get catalogTitle => 'الخدمات والأسعار';

  @override
  String get catalogSubtitle => 'الخدمات والإضافات وأحجام السيارات والأسعار';

  @override
  String get newService => 'خدمة جديدة';

  @override
  String get noServices => 'لا توجد خدمات بعد. أضف خدماتك وأسعارها.';

  @override
  String get serviceName => 'اسم الخدمة';

  @override
  String get categoryField => 'التصنيف';

  @override
  String get noCategory => 'بدون تصنيف';

  @override
  String get durationField => 'المدة (بالدقائق)';

  @override
  String get descriptionField => 'الوصف';

  @override
  String get isAddon => 'إضافة (تُباع مع خدمة أساسية)';

  @override
  String get serviceActive => 'متاحة للبيع';

  @override
  String get pricesSection => 'الأسعار';

  @override
  String get pricesIncludeVatHint => 'السعر الذي يدفعه العميل، شامل الضريبة';

  @override
  String get pricesExcludeVatHint => 'الأسعار قبل الضريبة';

  @override
  String get samePriceAllSizes => 'سعر واحد لكل أحجام السيارات';

  @override
  String get priceAllSizes => 'السعر (كل الأحجام)';

  @override
  String branchPricesFor(String branch) {
    return 'الأسعار في $branch';
  }

  @override
  String get branchPricesHint => 'اتركه فارغاً لاستخدام السعر العام';

  @override
  String amountInvalid(String example) {
    return 'أدخل مبلغاً مثل $example';
  }

  @override
  String get addonsSection => 'الإضافات';

  @override
  String fromPrice(String price) {
    return 'من $price';
  }

  @override
  String get unpriced => 'بدون سعر';

  @override
  String minutesShort(int count) {
    return '$count دقيقة';
  }

  @override
  String get inactiveLabel => 'غير مفعّلة';

  @override
  String get sizesTitle => 'أحجام السيارات';

  @override
  String get categoriesTitle => 'تصنيفات الخدمات';

  @override
  String get addSize => 'إضافة حجم';

  @override
  String get addCategory => 'إضافة تصنيف';

  @override
  String get nameField => 'الاسم';

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمة',
      many: '$count خدمة',
      few: '$count خدمات',
      two: 'خدمتان',
      one: 'خدمة واحدة',
      zero: 'لا توجد خدمات',
    );
    return '$_temp0';
  }

  @override
  String deleteEntryConfirm(String name) {
    return 'حذف «$name»؟';
  }

  @override
  String get daySat => 'السبت';

  @override
  String get daySun => 'الأحد';

  @override
  String get dayMon => 'الاثنين';

  @override
  String get dayTue => 'الثلاثاء';

  @override
  String get dayWed => 'الأربعاء';

  @override
  String get dayThu => 'الخميس';

  @override
  String get dayFri => 'الجمعة';

  @override
  String get queueTitle => 'الطابور';

  @override
  String get queueSubtitle => 'استقبال السيارات ومتابعتها حتى التسليم';

  @override
  String get queueTabWashing => 'قيد الغسيل';

  @override
  String get queueTabToday => 'اليوم';

  @override
  String get queueEmpty => 'لا توجد سيارات هنا.';

  @override
  String get noBranchAssigned => 'لم يتم تعيينك على فرع بعد.';

  @override
  String get statusWaiting => 'في الانتظار';

  @override
  String get statusInProgress => 'قيد الغسيل';

  @override
  String get statusQualityCheck => 'فحص الجودة';

  @override
  String get statusReady => 'جاهزة';

  @override
  String get statusDelivered => 'تم التسليم';

  @override
  String get statusCancelled => 'ملغاة';

  @override
  String get actionStart => 'ابدأ الغسيل';

  @override
  String get actionQualityCheck => 'إلى فحص الجودة';

  @override
  String get actionReady => 'جاهزة للتسليم';

  @override
  String get actionDeliver => 'تسليم للعميل';

  @override
  String get actionBackToWaiting => 'إرجاع للانتظار';

  @override
  String get actionBackToWashing => 'إعادة الغسيل';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get cancelReasonField => 'سبب الإلغاء';

  @override
  String get keepOrder => 'تراجع';

  @override
  String elapsedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count د', zero: 'الآن');
    return '$_temp0';
  }

  @override
  String get walkIn => 'عميل غير مسجل';

  @override
  String get checkInTitle => 'استقبال سيارة';

  @override
  String get checkIn => 'استقبال';

  @override
  String checkedIn(String reference) {
    return 'تم استقبال $reference';
  }

  @override
  String get matchingCars => 'سيارات مسجلة';

  @override
  String get shiftTitle => 'ورديتي';

  @override
  String get shiftSubtitle => 'فتح الصندوق وجرده عند الإقفال';

  @override
  String get noOpenShift => 'ليس لديك وردية مفتوحة. عُدّ النقد في الدرج وافتح ورديتك.';

  @override
  String get openingFloatField => 'النقد في الدرج عند الفتح';

  @override
  String get openingFloatHint => 'اتركه فارغاً إذا كان الدرج فارغاً.';

  @override
  String get openShift => 'فتح الوردية';

  @override
  String shiftOpenSince(String time) {
    return 'مفتوحة منذ $time';
  }

  @override
  String get shiftInvoices => 'الفواتير';

  @override
  String get shiftCashTaken => 'النقد المستلم';

  @override
  String get shiftDiscounts => 'الخصومات';

  @override
  String get expectedCash => 'المتوقع في الدرج';

  @override
  String get closeShift => 'إقفال الوردية';

  @override
  String get countedCashField => 'النقد المعدود في الدرج';

  @override
  String get drawerMatches => 'الدرج مطابق';

  @override
  String drawerShort(String amount) {
    return 'عجز $amount';
  }

  @override
  String drawerOver(String amount) {
    return 'زيادة $amount';
  }

  @override
  String get varianceNoteField => 'ما سبب الفرق؟';

  @override
  String get varianceLabel => 'الفرق';

  @override
  String get shiftClosed => 'تم إقفال الوردية';

  @override
  String get openShiftFirst => 'افتح ورديتك لتستطيع التحصيل.';

  @override
  String get checkoutTitle => 'التحصيل';

  @override
  String get collectPayment => 'تحصيل';

  @override
  String get payOnly => 'تحصيل فقط';

  @override
  String get payAndDeliver => 'تحصيل وتسليم';

  @override
  String get subtotalLabel => 'الخدمات';

  @override
  String get discountLabel => 'الخصم';

  @override
  String vatIncludedLabel(String rate) {
    return 'شامل الضريبة $rate%';
  }

  @override
  String vatAddedLabel(String rate) {
    return 'الضريبة $rate%';
  }

  @override
  String discountLimitHint(String limit) {
    return 'حدّك: $limit%';
  }

  @override
  String discountOverLimit(String limit) {
    return 'أكبر من حدّك $limit%';
  }

  @override
  String get discountReasonField => 'سبب الخصم';

  @override
  String get cashReceivedField => 'المبلغ المستلم';

  @override
  String get cashTooLittle => 'أقل من الإجمالي';

  @override
  String changeDue(String amount) {
    return 'الباقي للعميل: $amount';
  }

  @override
  String get paidTitle => 'تم الدفع';

  @override
  String get paidBadge => 'مدفوع';

  @override
  String get done => 'تم';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get inventoryTitle => 'المخزون';

  @override
  String get inventorySubtitle => 'المواد والأرصدة والمشتريات والجرد';

  @override
  String get stockTab => 'المخزون';

  @override
  String get purchasesTab => 'المشتريات';

  @override
  String get newPurchase => 'مشتريات جديدة';

  @override
  String get addMaterial => 'إضافة مادة';

  @override
  String get noMaterials => 'لا توجد مواد بعد. أضف المواد التي تستخدمها مثل الصابون والمناشف.';

  @override
  String lowStock(String min, String unit) {
    return 'منخفض: الحد الأدنى $min $unit';
  }

  @override
  String minStockLabel(String min, String unit) {
    return 'الحد الأدنى $min $unit';
  }

  @override
  String unitCostLabel(String cost, String unit) {
    return 'آخر سعر $cost لكل $unit';
  }

  @override
  String get stockCount => 'جرد';

  @override
  String get countedQuantity => 'الكمية المعدودة';

  @override
  String get stockHistory => 'السجل';

  @override
  String get noMovements => 'لا توجد حركات بعد.';

  @override
  String get movementPurchase => 'شراء';

  @override
  String get movementConsumption => 'استهلاك غسيل';

  @override
  String get movementCount => 'جرد';

  @override
  String get quantityInvalid => 'اكتب كمية، مثل 2.5';

  @override
  String get unitField => 'الوحدة';

  @override
  String get unitHint => 'مثل: لتر، كيلو، حبة';

  @override
  String get minStockField => 'الحد الأدنى';

  @override
  String get minStockHint => 'تُنبَّه عندما يصل الرصيد لهذا الحد.';

  @override
  String get noPurchases => 'لا مشتريات بعد.';

  @override
  String get materialsSection => 'المواد';

  @override
  String get addMaterialLine => 'إضافة مادة';

  @override
  String get quantityField => 'الكمية';

  @override
  String get unitPriceField => 'سعر الوحدة';

  @override
  String get addAtLeastOneMaterial => 'أضف مادة واحدة على الأقل.';

  @override
  String get purchaseCategoryHint => 'تُسجَّل المشتريات أيضاً كمصروف في هذا التصنيف.';

  @override
  String get serviceMaterials => 'المواد المستهلكة';

  @override
  String get serviceMaterialsHint => 'ما تستهلكه الخدمة في كل مرة، ويُخصم من مخزون الفرع عند بدء الغسيل.';

  @override
  String get expensesTitle => 'المصروفات';

  @override
  String get expensesSubtitle => 'المصروفات والموردون والمصاريف الدورية';

  @override
  String get owedTab => 'المستحقة';

  @override
  String get suppliersTab => 'الموردون';

  @override
  String get recurringTab => 'الدورية';

  @override
  String get newExpense => 'مصروف جديد';

  @override
  String get expenseCategories => 'تصنيفات المصروفات';

  @override
  String get expenseCategory => 'التصنيف';

  @override
  String get amountField => 'المبلغ';

  @override
  String get paymentMethodField => 'طريقة الدفع';

  @override
  String get payFromDrawer => 'من الدرج';

  @override
  String get payCash => 'نقداً';

  @override
  String get payBankTransfer => 'تحويل بنكي';

  @override
  String get payCard => 'بطاقة';

  @override
  String get notPaidYet => 'غير مدفوع';

  @override
  String get payFromDrawerHint => 'يُخصم من درج ورديتك اليوم، ويُحسب عند جرد الإقفال.';

  @override
  String get supplierField => 'المورد';

  @override
  String get noSupplier => 'بدون مورد';

  @override
  String get owedToSupplierHint => 'يُسجَّل مستحقاً لهذا المورد حتى يُدفع.';

  @override
  String get expenseDate => 'التاريخ';

  @override
  String get payExpense => 'الدفع بـ';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get totalOwed => 'إجمالي المستحق';

  @override
  String get totalSpent => 'الإجمالي';

  @override
  String get nothingOwed => 'لا توجد مستحقات.';

  @override
  String get noExpenses => 'لا مصروفات في هذه الفترة.';

  @override
  String get recurringBadge => 'دوري';

  @override
  String get addSupplier => 'إضافة مورد';

  @override
  String get noSuppliers => 'لا يوجد موردون بعد.';

  @override
  String owedAmount(String amount) {
    return 'مستحق $amount';
  }

  @override
  String get addRecurring => 'إضافة مصروف دوري';

  @override
  String get recurringHint => 'في تاريخ الاستحقاق يُسجَّل المصروف الدوري مستحقاً حتى يُدفع.';

  @override
  String get noRecurring => 'لا مصروفات دورية.';

  @override
  String nextDue(String date) {
    return 'القادم: $date';
  }

  @override
  String get nextDueField => 'تاريخ الاستحقاق القادم';

  @override
  String get recurringDescriptionHint => 'مثل: إيجار المحل';

  @override
  String get frequencyWeekly => 'أسبوعي';

  @override
  String get frequencyMonthly => 'شهري';

  @override
  String get frequencyYearly => 'سنوي';

  @override
  String get cashPaidOut => 'مصروفات من الدرج';

  @override
  String get expensesTotal => 'المصروفات';

  @override
  String get netTotal => 'الصافي';

  @override
  String get dailySalesTitle => 'تقرير المبيعات';

  @override
  String get dailySalesSubtitle => 'المبيعات والسيارات والموظفون لأي يوم';

  @override
  String get previousDay => 'اليوم السابق';

  @override
  String get nextDay => 'اليوم التالي';

  @override
  String get today => 'اليوم';

  @override
  String get noSalesThatDay => 'لا مبيعات ولا سيارات في هذا اليوم.';

  @override
  String get salesTotal => 'المبيعات';

  @override
  String get averageTicket => 'متوسط الفاتورة';

  @override
  String get vatTotal => 'الضريبة';

  @override
  String get carsCheckedIn => 'سيارات مستقبَلة';

  @override
  String get carsInQueue => 'ما زالت في الطابور';

  @override
  String get byCashier => 'الكاشير';

  @override
  String get byHour => 'المبيعات حسب الساعة';

  @override
  String invoicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فاتورة',
      few: '$count فواتير',
      two: 'فاتورتان',
      one: 'فاتورة واحدة',
    );
    return '$_temp0';
  }

  @override
  String carsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سيارة',
      few: '$count سيارات',
      two: 'سيارتان',
      one: 'سيارة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get chooseWasher => 'اختر العامل الذي سيغسل السيارة.';

  @override
  String get noWashersInBranch => 'لا يوجد موظفون في هذا الفرع بعد؛ أضفهم من «الموظفون».';

  @override
  String get isPackage => 'باقة';

  @override
  String get isPackageHint => 'تجمع خدمات موجودة بسعر مخفّض';

  @override
  String get packagesSection => 'الباقات';

  @override
  String get packageServicesSection => 'خدمات الباقة';

  @override
  String get packageNeedsTwoServices => 'اختر خدمتين على الأقل';

  @override
  String get packageDiscountSection => 'خصم الباقة';

  @override
  String get discountPercent => 'نسبة';

  @override
  String get packageDiscountField => 'الخصم';

  @override
  String get packagePricesSection => 'السعر حسب الحجم';

  @override
  String discountOff(String discount) {
    return 'خصم $discount';
  }

  @override
  String packageSaves(String amount) {
    return 'وفّرت $amount';
  }

  @override
  String get inspectionHint => 'أشّر على كل خدمة تمت بشكل صحيح';

  @override
  String get passInspection => 'اجتازت الفحص – جاهزة';

  @override
  String get inspectionPassed => 'اجتازت الفحص';

  @override
  String get inspectionFailed => 'أُعيدت للغسيل';

  @override
  String get staffPinField => 'الرمز السري PIN (4–6 أرقام)';

  @override
  String get staffPinHint => 'ليظهر في «تبديل المستخدم» على الأجهزة المشتركة';

  @override
  String get staffPinKeepHint => 'لديه رمز؛ اتركه فارغاً للإبقاء عليه';

  @override
  String get maxDiscountField => 'أقصى خصم';

  @override
  String maxDiscountHint(String limit) {
    return 'حتى $limit% (حدّك أنت)';
  }

  @override
  String get percentInvalid => 'اكتب نسبة من 0 إلى 100';

  @override
  String get registerWalkInHint => 'اختياري: يُحفظ العميل وسيارته تلقائياً';

  @override
  String get servicesSection => 'الخدمات';

  @override
  String get chooseSizeForPrices => 'اختر حجم السيارة لتظهر الأسعار.';

  @override
  String get chooseMainService => 'اختر خدمة أساسية واحدة على الأقل.';

  @override
  String get bayField => 'الرصيف';

  @override
  String get noBayYet => 'لاحقًا';

  @override
  String get washersSection => 'العمال';

  @override
  String get orderTotal => 'الإجمالي';

  @override
  String aboutMinutes(int count) {
    return 'حوالي $count د';
  }

  @override
  String checkedInBy(String name) {
    return 'استقبلها $name';
  }

  @override
  String get historyTitle => 'السجل';

  @override
  String get assignmentTitle => 'الرصيف والعمال والملاحظات';

  @override
  String cancelledBecause(String reason) {
    return 'أُلغي: $reason';
  }
}
