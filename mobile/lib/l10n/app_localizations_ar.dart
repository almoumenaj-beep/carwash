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
  String get shiftTitle => 'الكاشير';

  @override
  String get shiftSubtitle => 'افتح الكاشير، وعند الإقفال اجرد الكاش وطابقه';

  @override
  String get noOpenShift => 'الكاشير غير مفتوح. عُدّ النقد في الدرج وافتح الكاشير.';

  @override
  String get openingFloatField => 'النقد في الدرج عند الفتح';

  @override
  String get openingFloatHint => 'اتركه فارغاً إذا كان الدرج فارغاً.';

  @override
  String get openShift => 'فتح الكاشير';

  @override
  String shiftOpenSince(String time) {
    return 'مفتوح منذ $time';
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
  String get closeShift => 'إقفال الكاشير';

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
  String get shiftClosed => 'تم إقفال الكاشير';

  @override
  String get openShiftFirst => 'افتح الكاشير لتستطيع التحصيل.';

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
  String get darkMode => 'الوضع الليلي';

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
  String get payFromDrawerHint => 'يُخصم من درج الكاشير اليوم، ويُحسب عند جرد الإقفال.';

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
  String get chooseSizeForPrices => 'بعدها تظهر الخدمات والباقات والإضافات بأسعارها لهذا الحجم.';

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

  @override
  String get clockInAt => 'سجّل الحضور في';

  @override
  String get notClockedIn => 'لم تسجّل حضورك اليوم';

  @override
  String clockedInSince(String time) {
    return 'في الدوام منذ $time';
  }

  @override
  String get clockIn => 'حضور';

  @override
  String get clockOut => 'انصراف';

  @override
  String get staffAffairsTitle => 'شؤون الموظفين';

  @override
  String get staffAffairsSubtitle => 'الرواتب والعمولات والحضور';

  @override
  String get employeesTab => 'الموظفون';

  @override
  String get attendanceTab => 'الحضور';

  @override
  String get payrollTab => 'الرواتب';

  @override
  String get noCommission => 'بدون عمولة';

  @override
  String commissionPerCar(String amount) {
    return 'عمولة $amount للسيارة';
  }

  @override
  String commissionPercent(String percent) {
    return 'عمولة $percent% من السيارة';
  }

  @override
  String salaryLabel(String amount) {
    return 'راتب $amount';
  }

  @override
  String get monthlySalaryField => 'الراتب الشهري';

  @override
  String get commissionField => 'العمولة';

  @override
  String get noCommissionShort => 'بدون';

  @override
  String get perCarShort => 'للسيارة';

  @override
  String get perCarField => 'المبلغ عن كل سيارة';

  @override
  String get percentOfCarField => 'النسبة من المبلغ النهائي للفاتورة';

  @override
  String get commissionSplitHint => 'إذا غسل السيارة أكثر من عامل تُقسم العمولة بينهم';

  @override
  String get noAttendance => 'لا يوجد حضور في هذا اليوم';

  @override
  String stillAtWork(String time) {
    return 'منذ $time – ما زال في الدوام';
  }

  @override
  String hoursWorked(String hours) {
    return '$hours س';
  }

  @override
  String get calculateThisMonth => 'احسب رواتب هذا الشهر';

  @override
  String get calculateLastMonth => 'الشهر الماضي';

  @override
  String get noPayroll => 'لم تُحسب رواتب بعد';

  @override
  String get payrollPaid => 'مدفوعة';

  @override
  String get payrollDraft => 'مسودة – يُعاد حسابها حتى الدفع';

  @override
  String commissionAmount(String amount) {
    return 'عمولة $amount';
  }

  @override
  String get payPayroll => 'ادفع الرواتب';

  @override
  String get edit => 'تعديل';

  @override
  String get notSet => 'غير محدد';

  @override
  String get branchField => 'الفرع';

  @override
  String get equipmentTitle => 'المعدات والصيانة';

  @override
  String get equipmentSubtitle => 'الأجهزة ومواعيد صيانتها والأعطال';

  @override
  String get addEquipment => 'إضافة جهاز';

  @override
  String get editEquipment => 'تعديل الجهاز';

  @override
  String get noEquipment => 'لم تُضف أجهزة بعد. أضف مكائن الضغط والمكانس والكمبرسورات لتتابع صيانتها.';

  @override
  String get equipmentInService => 'يعمل';

  @override
  String get equipmentOutOfService => 'معطّل';

  @override
  String get equipmentRetired => 'خارج الخدمة نهائياً';

  @override
  String maintenanceOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوماً',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return 'الصيانة متأخرة $_temp0';
  }

  @override
  String get maintenanceDueToday => 'الصيانة مستحقة اليوم';

  @override
  String maintenanceDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوماً',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return 'الصيانة بعد $_temp0';
  }

  @override
  String maintenanceDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جهازاً تحتاج صيانة الآن',
      few: '$count أجهزة تحتاج صيانة الآن',
      two: 'جهازان يحتاجان صيانة الآن',
      one: 'جهاز واحد يحتاج صيانة الآن',
    );
    return '$_temp0';
  }

  @override
  String get reportBreakdown => 'الإبلاغ عن عطل';

  @override
  String get backInService => 'عاد للعمل';

  @override
  String get retireEquipment => 'إخراجه من الخدمة نهائياً';

  @override
  String get recordMaintenance => 'تسجيل صيانة';

  @override
  String get noPeriodicMaintenance => 'بدون صيانة دورية';

  @override
  String maintenanceEvery(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوماً',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return 'صيانة كل $_temp0';
  }

  @override
  String get nextMaintenance => 'الصيانة القادمة';

  @override
  String get serialNumberField => 'الرقم التسلسلي';

  @override
  String get purchaseSection => 'الشراء';

  @override
  String get maintenanceHistory => 'سجل الصيانة';

  @override
  String get noMaintenanceYet => 'لا توجد صيانة مسجلة';

  @override
  String get periodicMaintenance => 'صيانة دورية';

  @override
  String get repairMaintenance => 'إصلاح عطل';

  @override
  String get equipmentNameField => 'اسم الجهاز';

  @override
  String get equipmentNameHint => 'مثال: مكينة الضغط 1';

  @override
  String get maintenanceIntervalField => 'الصيانة الدورية كل';

  @override
  String get daysUnit => 'يوم';

  @override
  String get maintenanceIntervalHint => 'اتركه فارغاً إذا لا يحتاج صيانة دورية';

  @override
  String get maintenanceIntervalInvalid => 'اكتب عدد أيام من 1 إلى 3650';

  @override
  String get purchaseDateField => 'تاريخ الشراء';

  @override
  String get purchaseCostField => 'سعر الشراء';

  @override
  String get periodicMaintenanceHint => 'يبدأ العدّ للصيانة القادمة من تاريخ هذه الصيانة';

  @override
  String get repairMaintenanceHint => 'إذا كان الجهاز معطّلاً يعود «يعمل» بعد الإصلاح';

  @override
  String get maintenanceDateField => 'تاريخ الصيانة';

  @override
  String get whatWasDoneField => 'ماذا تم؟';

  @override
  String get maintenanceCostField => 'التكلفة';

  @override
  String get maintenanceCostHint => 'اختياري: تُسجَّل مصروفاً على فرع الجهاز';

  @override
  String get financialReportsTitle => 'التقارير المالية';

  @override
  String get financialReportsSubtitle => 'الأرباح والخسائر والتدفق النقدي والربحية';

  @override
  String get thisYear => 'هذه السنة';

  @override
  String get customPeriod => 'فترة أخرى';

  @override
  String get profitLossTab => 'الأرباح والخسائر';

  @override
  String get cashFlowTab => 'التدفق النقدي';

  @override
  String get profitabilityTab => 'الربحية';

  @override
  String get noFiguresInPeriod => 'لا توجد مبيعات ولا مصروفات في هذه الفترة';

  @override
  String get profitLabel => 'صافي الربح';

  @override
  String get lossLabel => 'صافي الخسارة';

  @override
  String marginLabel(String percent) {
    return 'هامش الربح $percent%';
  }

  @override
  String get revenueSection => 'الإيرادات';

  @override
  String get grossSales => 'المبيعات قبل الخصم';

  @override
  String get netSales => 'صافي المبيعات';

  @override
  String get totalExpenses => 'إجمالي المصروفات';

  @override
  String get ofWhichOwed => 'منها غير مدفوع';

  @override
  String get profitLossNote =>
      'صافي المبيعات بدون الضريبة. المصروفات تُحسب بتاريخها مدفوعة أو مستحقة: المواد عند شرائها، والرواتب عند دفعها.';

  @override
  String get moneyIn => 'الداخل';

  @override
  String get moneyOut => 'الخارج';

  @override
  String get netCashFlow => 'صافي التدفق';

  @override
  String stillOwed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستحقاً غير مدفوع',
      few: '$count مستحقات غير مدفوعة',
      two: 'مستحقان غير مدفوعين',
      one: 'مستحق واحد غير مدفوع',
      zero: 'لا مستحقات',
    );
    return '$_temp0';
  }

  @override
  String get byDay => 'حسب اليوم';

  @override
  String get cashFlowNote =>
      'الداخل ما دفعه العملاء، والخارج المصروفات المدفوعة فعلاً بتاريخ دفعها. المستحقات هي المبالغ غير المدفوعة حتى اليوم.';

  @override
  String get byBranch => 'حسب الفرع';

  @override
  String get materialsCost => 'المواد';

  @override
  String get serviceProfitNote =>
      'صافي المبيعات بعد الخصم والضريبة، ناقص تكلفة المواد التقديرية بأسعار المواد الحالية.';

  @override
  String get payLabel => 'الأجر';

  @override
  String get washerProfitNote => 'قيمة كل سيارة تُقسم بين عمالها، والأجر هو الراتب والعمولة في مسيرات رواتب الفترة.';

  @override
  String get appointmentsTitle => 'الحجوزات';

  @override
  String get appointmentsSubtitle => 'مواعيد السيارات واستقبالها عند الوصول';

  @override
  String get newBooking => 'حجز جديد';

  @override
  String get changeBooking => 'تعديل الحجز';

  @override
  String get checkInBooking => 'استقبال السيارة المحجوزة';

  @override
  String get book => 'احجز';

  @override
  String bookedAt(String time) {
    return 'تم الحجز الساعة $time';
  }

  @override
  String get bookingPhoneHint => 'للتواصل مع العميل؛ مطلوب إذا لم تكن السيارة مسجلة';

  @override
  String get bookingTimeSection => 'الموعد';

  @override
  String get chooseServicesForTimes => 'اختر الخدمات لتظهر الأوقات المتاحة.';

  @override
  String get noFreeTimes => 'لا توجد أوقات متاحة في هذا اليوم.';

  @override
  String get appointmentBooked => 'محجوز';

  @override
  String get appointmentCheckedIn => 'وصل';

  @override
  String get appointmentCancelled => 'ملغى';

  @override
  String get appointmentNoShow => 'لم يحضر';

  @override
  String get noBookingsThatDay => 'لا توجد حجوزات في هذا اليوم';

  @override
  String get cancelBooking => 'إلغاء الحجز';

  @override
  String get markNoShow => 'لم يحضر';

  @override
  String get openOrder => 'فتح الطلب';

  @override
  String get back => 'رجوع';

  @override
  String get chooseSizeFirst => 'اختر حجم السيارة أولاً';

  @override
  String get autoClockedOut => 'انصراف تلقائي عند الإغلاق';

  @override
  String get groupDaily => 'العمل اليومي';

  @override
  String get groupMore => 'الإدارة';

  @override
  String get groupFinance => 'الشؤون المالية';

  @override
  String get groupResources => 'المخزون والمعدات';

  @override
  String get groupPeople => 'الموظفون';

  @override
  String get groupSetup => 'الإعدادات';

  @override
  String get manageCategories => 'تصنيفات المصروفات';

  @override
  String get manageCategoriesHint => 'إضافة تصنيف أو تعديله أو إيقافه';

  @override
  String get appointmentConfirmed => 'مؤكد';

  @override
  String get appointmentLate => 'متأخر';

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String get confirmBookingHint => 'بعد التواصل مع العميل وتأكيده الحضور';

  @override
  String get allFilter => 'الكل';

  @override
  String get graceMinutesField => 'مهلة انتظار الحجز المتأخر (بالدقائق)';

  @override
  String get minutesUnit => 'دقيقة';

  @override
  String get graceMinutesHint =>
      'عدد الدقائق بعد موعد الحجز، مثلاً 30 تعني نصف ساعة. إذا لم تصل السيارة خلالها يصير الحجز «لم يحضر» تلقائياً. اتركه فارغاً لإيقاف ذلك.';

  @override
  String get graceMinutesInvalid => 'اكتب عدد الدقائق من 5 إلى 720، أو اتركه فارغاً';

  @override
  String checkedInWithBooking(String reference, String time) {
    return 'تم استقبال $reference وربطه بحجز الساعة $time';
  }

  @override
  String get manageServiceCategoriesHint => 'إضافة تصنيف للخدمات أو تعديله أو إيقافه';

  @override
  String get manageVehicleSizesHint => 'الأحجام التي تختلف الأسعار حسبها، مثل صالون ودفع رباعي';

  @override
  String get clockInToStart => 'سجّل حضورك لتبدأ العمل';

  @override
  String get clockInToStartHint => 'تظهر أقسام التطبيق بعد الضغط على «حضور» في الأعلى.';

  @override
  String get endOfDayQuestion => 'هل انتهى دوامك؟';

  @override
  String get endOfDayHint => 'ما زلت مسجّلاً في الدوام. الخروج من التطبيق وحده لا يسجّل انصرافك.';

  @override
  String get signOutOnly => 'خروج فقط';

  @override
  String get clockOutAndSignOut => 'انصراف وخروج';

  @override
  String get requiresAttendanceField => 'يلزم تسجيل الحضور قبل العمل';

  @override
  String get requiresAttendanceHint => 'لا تظهر أقسام التطبيق لهذا الدور قبل تسجيل الحضور';

  @override
  String get sharedDeviceField => 'جهاز مشترك';

  @override
  String get sharedDeviceHint => 'فعّله لجهاز يستخدمه أكثر من موظف، فيظهر عليه «تبديل المستخدم» بالرمز السري';

  @override
  String get sharedDeviceAllBranches => 'تبديل المستخدم مفعّل لموظفي كل الفروع';

  @override
  String sharedDeviceBranch(String branch) {
    return 'تبديل المستخدم مفعّل لموظفي $branch';
  }

  @override
  String get sharedDeviceWhichBranch => 'موظفو أي فرع يستخدمون هذا الجهاز؟';

  @override
  String get dailyUsageTab => 'الصرف اليومي';

  @override
  String get issueMaterials => 'صرف مواد';

  @override
  String get movementIssue => 'صرف مواد';

  @override
  String get issueNoteField => 'الغرض (اختياري)';

  @override
  String get issueNoteHint => 'مثال: مواد اليوم';

  @override
  String get nothingInStock => 'لا توجد مواد متوفرة في هذا الفرع. سجّل مشتريات أولاً.';

  @override
  String get noUsageThatDay => 'لم يُصرف شيء من المخزون في هذا اليوم';

  @override
  String usedByWashes(String value) {
    return 'الغسيل: $value';
  }

  @override
  String issuedByHand(String value) {
    return 'مصروف: $value';
  }

  @override
  String get usageCostTotal => 'تكلفة ما صُرف';

  @override
  String get usageCostHint => 'تقديرية بأسعار المواد الحالية، ومسجّلة أصلاً كمصروف عند الشراء';

  @override
  String get issuesByHandSection => 'عمليات الصرف';

  @override
  String supplierLabel(String value) {
    return 'المورد: $value';
  }

  @override
  String get stockIssueSubtitle => 'صرف مواد اليوم للموظفين';

  @override
  String get receivedByField => 'الموظف المستلم';

  @override
  String receivedByLabel(String name) {
    return 'استلمها $name';
  }

  @override
  String availableQuantity(String value) {
    return 'المتوفر: $value';
  }

  @override
  String onlyInStock(String name, String quantity, String unit) {
    return 'المتوفر من $name $quantity $unit فقط';
  }

  @override
  String get chooseReceiver => 'اختر الموظف المستلم';

  @override
  String get materialsIssued => 'تم صرف المواد';

  @override
  String get materialField => 'المادة';

  @override
  String get chooseMaterialFirst => 'اختر المادة';

  @override
  String get addOneMaterial => 'أضف مادة واحدة على الأقل إلى القائمة';

  @override
  String issueListSection(int count) {
    return 'المواد المراد صرفها ($count)';
  }

  @override
  String get issueListEmpty => 'اختر مادة واكتب كميتها، ثم اضغط «إضافة مادة».';

  @override
  String get movementReversal => 'إلغاء صرف';

  @override
  String get cancelIssueTitle => 'إلغاء الصرف';

  @override
  String cancelIssueConfirm(String what) {
    return 'إلغاء صرف $what؟ تعود الكمية إلى المخزون، ويبقى الصرف في السجل كملغى.';
  }

  @override
  String issueCancelledBy(String name) {
    return 'ألغاه $name';
  }

  @override
  String get movementCancellation => 'إلغاء شراء';

  @override
  String get cancelPurchase => 'إلغاء الشراء';

  @override
  String get cancelPurchaseConfirm =>
      'تُخصم كميات هذا الشراء من المخزون ويُحذف مصروفه من المصروفات، ويبقى الشراء في القائمة كملغى.';

  @override
  String get newSupplierButton => 'مورد جديد';

  @override
  String get sourcePurchase => 'مشتريات مخزون';

  @override
  String get sourcePayroll => 'رواتب';

  @override
  String get sourceMaintenance => 'صيانة';

  @override
  String get materialsExpenseTitle => 'هل هذه مواد للمخزون؟';

  @override
  String get materialsExpenseHint =>
      'سجّلها من المخزون ← مشتريات جديدة، فتزيد الكمية ويُسجَّل المصروف تلقائياً. تسجيلها هنا لا يزيد المخزون، وتسجيلها في المكانين يحسبها مرتين.';

  @override
  String get openInventory => 'فتح المخزون';

  @override
  String get cancelMaintenance => 'إلغاء الصيانة';

  @override
  String get cancelMaintenanceConfirm =>
      'يُحذف مصروفها من المصروفات إن وُجد، ويرجع موعد الصيانة القادمة وحالة الجهاز كما كانا، ويبقى السطر في السجل كملغى.';

  @override
  String get cancelPayrollPayment => 'إلغاء دفع الرواتب';

  @override
  String get cancelPayrollPaymentConfirm =>
      'يُحذف مصروف هذا الشهر من المصروفات ويرجع المسير مسودة، فتراجعه وتدفعه من جديد. إذا كان المال قد صُرف فعلاً للموظفين فهذا لا يسترده.';

  @override
  String get newMaterialOption => '+ مادة جديدة…';

  @override
  String get addToList => 'إضافة المادة';

  @override
  String purchaseListSection(int count) {
    return 'المواد المضافة ($count)';
  }

  @override
  String get purchaseListEmpty => 'اختر مادة واكتب كميتها وسعرها، ثم اضغط «إضافة المادة».';

  @override
  String get savePurchase => 'حفظ المشتريات';

  @override
  String get payBenefit => 'بنفت';

  @override
  String get shiftCardTaken => 'مدفوعات البطاقة';

  @override
  String get shiftBenefitTaken => 'مدفوعات بنفت';

  @override
  String get cardPaymentHint => 'سجّل الدفع بعد نجاح العملية على جهاز البطاقة.';

  @override
  String get benefitPaymentHint => 'سجّل الدفع بعد أن تتأكد من وصول المبلغ إلى حساب المغسلة.';
}
