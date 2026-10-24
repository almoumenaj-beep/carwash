# خطة مشروع نظام إدارة المغاسل (CarWash SaaS)

> **هذا الملف هو المرجع الحي للمشروع.** يُحدَّث بعد إنجاز كل مهمة: الخطة التفصيلية + جدول التقدّم + سجل القرارات + سجل التغييرات.

**الإنجاز الإجمالي: 9%** · آخر تحديث: 2026-10-24 · المرحلة الحالية: 0 – الأساس

الرموز: `[ ]` لم يبدأ · `[~]` قيد التنفيذ · `[x]` مكتمل (مع التاريخ)

## الفهرس
1. [جدول التقدّم (Progress Tracker)](#a-جدول-التقدّم-progress-tracker)
2. [ما التالي؟](#b-ما-التالي)
3. [السياق والقرارات المعتمدة](#0-السياق-والقرارات-المعتمدة)
4. [Flutter أم Filament؟](#1-القرار-الأساسي-flutter-أم-filament)
5. [المعمارية العامة](#2-المعمارية-العامة) (Multi-tenancy · المصادقة · الأدوار والصلاحيات · المال)
6. [الوحدات](#3-الوحدات-modules-ونطاق-كل-منها)
7. [قاعدة البيانات](#4-تصميم-قاعدة-البيانات-الجداول-الرئيسية)
8. [الاتصال بالخادم](#5-الاتصال-بالخادم-online-only)
9. [تصميم الـ API](#6-تصميم-الـ-api-laravel)
10. [تطبيق Flutter](#7-تطبيق-flutter)
11. [الأمن](#8-الأمن-والامتثال)
12. [خارطة الطريق](#9-خارطة-الطريق-تقديرية-لمطوّر-مطوّرَين)
13. [التحقق](#10-التحقق-verification)
14. [سجل القرارات والتغييرات والمخاطر](#c-سجل-القرارات-adr)

---

## (A) جدول التقدّم (Progress Tracker)

### المرحلة 0 – الأساس (≈ 17%)
- [x] جمع المتطلبات وحسم القرارات (Multi-tenant، Flutter، أونلاين فقط، ar/en) — 2026-10-24
- [x] كتابة الخطة التقنية — 2026-10-24
- [x] إنشاء `docs/PROJECT_PLAN.md` — 2026-10-24
- [x] إعداد البيئة (PHP 8.4.27 + Composer 2.10 + MySQL 8.4.13 + phpMyAdmin عبر XAMPP على المنفذ 3307) و`.env` — 2026-10-24
- [x] استبدال MariaDB 10.4 بـ MySQL 8.4.13 داخل XAMPP + Laravel Boost (guidelines/skills/MCP) — 2026-10-24
- [x] تثبيت الحزم الأساسية (Sanctum, permission+Teams, activitylog, medialibrary, scramble) + UUID للمستخدمين + اختبارات على MySQL (`carwash_testing`) — 2026-10-24
- [x] Multi-tenancy: `BelongsToTenant` + `TenantScope` + `TenantContext` + middleware `SetTenantContext` + `tenants` + `branches` + `users.tenant_id` + اختبارات العزل (نموذج + API) — 2026-10-24
- [ ] نظام الأدوار والصلاحيات: Permission Catalog + Seeder + الأدوار الافتراضية + Policies
- [ ] API الأدوار: `/permissions` `/roles` `/users/{id}/roles` `/me`
- [ ] Auth: Sanctum + PIN سريع + الأجهزة
- [ ] تثبيت Flutter SDK وإنشاء المشروع + l10n (ar/en) + Riverpod + Dio
- [ ] شاشات Flutter: Login + PermissionGuard + إدارة الأدوار والموظفين
- [ ] CI (اختبارات + Pint + Flutter analyze)

### المرحلة 1 – MVP تشغيلي (0%)
- [ ] الفروع والإعدادات والأرصفة
- [ ] كتالوج الخدمات والأسعار حسب حجم السيارة والإضافات
- [ ] العملاء والسيارات
- [ ] أوامر العمل + الحالات + لوحة الطابور (Reverb)
- [ ] POS نقدي + الخصومات + الضريبة
- [ ] الإيصال الحراري/PDF
- [ ] إقفال الوردية وجرد الصندوق
- [ ] تقرير المبيعات اليومي
- [ ] تجربة Pilot على مغسلة حقيقية

### المرحلة 2 – الموارد والمال (0%)
- [ ] المخزون + الموردون + أوامر الشراء + استهلاك الخدمات (BOM)
- [ ] المعدات والصيانة الدورية
- [ ] الموظفون: الحضور، الورديات، العمولات، السلف، مسير الرواتب
- [ ] المصاريف (الدورية وغير الدورية) وذمم الموردين
- [ ] تقارير: P&L، التدفق النقدي، ربحية الخدمة/الفرع/الموظف

### المرحلة 3 – التواصل والدفع (0%)
- [ ] قوالب الرسائل + واتساب/SMS/Push
- [ ] المحفزات التلقائية والحملات واستبيان الرضا
- [ ] الدفع الإلكتروني (بوابة محلية)
- [ ] الحجوزات والمواعيد
- [ ] المحفظة والنقاط والعضويات

### المرحلة 4 – SaaS والإطلاق (0%)
- [ ] لوحة Filament للمشغّل (tenants، خطط، اشتراكات)
- [ ] Onboarding مغسلة جديدة + فوترة الاشتراكات
- [ ] المراقبة (Sentry) والنسخ الاحتياطي
- [ ] النشر على Play Store / App Store / الويب

### المرحلة 5 – لاحقاً (0%)
- [ ] تطبيق العميل (حجز/تتبع/محفظة)
- [ ] الفاتورة الإلكترونية (ZATCA وما يماثلها)
- [ ] ANPR وتكاملات محاسبية

## (B) ما التالي؟
1. نظام الأدوار والصلاحيات: Permission Catalog + Seeder + الأدوار الافتراضية (تُنسخ لكل tenant) + `branch_user` لنطاق الفروع + Policies.
2. API الأدوار: `/permissions` `/roles` `/users/{id}/roles` `/me`.

---

## 0) السياق والقرارات المعتمدة

**الحالة الحالية:** Laravel 13 على Windows/XAMPP مباشرة (بدون WSL — انظر «بيئة التطوير الحالية»)، مع Boost والحزم الأساسية مثبّتة. يُثبَّت Flutter SDK عند بدء التطبيق.

| البند | القرار |
|---|---|
| النطاق | SaaS متعدد المغاسل (Multi-tenant) → كل مغسلة = Tenant، ولها فروع |
| المنصات | Flutter: Android + iOS + Web |
| التشغيل | أونلاين فقط، واجهة عربية RTL + إنجليزية |
| التواصل | دفع إلكتروني + إشعارات واتساب / SMS / Push |
| الإدارة | أدوار وصلاحيات (RBAC) لكل موظف، يديرها المالك من التطبيق |

---

## 1) القرار الأساسي: Flutter أم Filament؟

**التوصية: هجين مدروس — Flutter هو التطبيق الرئيسي، + لوحة Filament صغيرة لمشغّل المنصة فقط.**

| المعيار | Flutter + API | Filament فقط |
|---|---|---|
| الطباعة الحرارية (Bluetooth/USB) | ✅ | ❌ ضعيف جداً |
| الموظفون يعملون من الجوال/التابلت (تغيير حالة السيارة، صور قبل/بعد، مسح QR) | ✅ ممتاز | ⚠️ يعمل لكن تجربة ضعيفة |
| إشعارات Push فورية | ✅ | ⚠️ محدود |
| سرعة البناء (MVP) | ⚠️ أبطأ ~40–60% (واجهتان: API + تطبيق) | ✅ الأسرع |
| لوحة المالك على المتصفح | ✅ Flutter Web | ✅ ممتاز |
| تكلفة الصيانة | أعلى (كود Dart + PHP) | أقل |

**لماذا الهجين؟** المستخدم الأساسي (كاشير/عامل/مالك) يحتاج تطبيقاً سريعاً، يطبع الإيصالات ويعمل بسلاسة على الجوال والتابلت. أما مشغّل المنصة فيحتاج لوحة CRUD للـ tenants والاشتراكات والدعم — Filament يبنيها في أيام، فلا داعي لكتابتها بـ Flutter.

> **مخاطر:** (1) النظام يعتمد على اتصال دائم؛ انقطاع الإنترنت يعني توقف الكاشير مؤقتاً (قرار معتمد، ويمكن إضافة الأوفلاين مستقبلاً بإعادة تصميم جزء البيانات). (2) Flutter Web لا يدعم الطباعة الحرارية جيداً — لوحة إدارة/تقارير للمالك فقط. (3) iOS يتطلب حساب Apple Developer ($99/سنة) وجهاز Mac للبناء (أو CI سحابي مثل Codemagic).

---

## 2) المعمارية العامة

```
 ┌──────────────── Flutter (Android / iOS / Web) ────────────────┐
 │  Riverpod · go_router · Dio · intl(ar/en) · Printing           │
 └───────────────────────────┬────────────────────────────────────┘
                             │ HTTPS REST /api/v1 + WebSocket (Reverb)
 ┌───────────────────────────▼────────────────────────────────────┐
 │ Laravel 13 API  (Sanctum · Policies · Form Requests · Resources)│
 │  Domain modules (Actions/Services) · Queue (database → Redis)   │
 │  Scheduler · Events/Listeners · Notifications                   │
 ├──────────────┬───────────────┬──────────────┬──────────────────┤
 │ MySQL 8      │ cache/queue   │ S3/MinIO     │ Providers        │
 │ (tenant_id)  │ (DB الآن)     │ صور/ملفات    │ WhatsApp/SMS/FCM │
 │              │               │              │ Payment/ZATCA    │
 └──────────────┴───────────────┴──────────────┴──────────────────┘
        + Filament Panel (Super Admin: tenants, plans, support)
```

### 2.1 Multi-tenancy
- **قاعدة بيانات واحدة + عمود `tenant_id`** على كل جدول (وليس DB لكل مغسلة). السبب: أبسط للنسخ الاحتياطي والتقارير والتكلفة. (التوسع لاحقاً بـ sharding عند الحاجة.)
- Trait اسمه `BelongsToTenant` + Global Scope يضيف `where tenant_id = ?` تلقائياً، ويملأ `tenant_id` عند الإنشاء. الـ tenant يُستخرج من المستخدم المصادَق (وليس من الطلب أبداً).
- كل جدول تشغيلي يحمل أيضاً `branch_id` عند الحاجة، وفهارس مركبة تبدأ بـ `(tenant_id, …)`.
- MySQL لا يدعم Row-Level Security، لذا العزل يعتمد على الـ Global Scope + الاختبارات (+ فحص `tenant_id` في الـ Policies).
- اختبارات إلزامية تثبت أن tenant A لا يرى بيانات tenant B في **كل** endpoint.

### 2.2 المصادقة
- Laravel **Sanctum** (tokens لكل جهاز، قابلة للإلغاء) + تسجيل دخول بالبريد/الجوال + **PIN سريع** للكاشير للتبديل بين الموظفين على نفس الجهاز.
- كل موظف له حساب مستخدم (`users`) مرتبط بملف موظف (`employees`) ودور واحد أو أكثر.

### 2.3 الأدوار والصلاحيات (Roles & Permissions) — نظام RBAC كامل
**الهدف:** لكل موظف دور وصلاحيات محددة، والمالك يتحكم بها من داخل التطبيق دون تدخل مطوّر.

**النموذج:**
- **Permissions (صلاحيات):** ثابتة معرّفة في الكود (Permission Catalog) بصيغة `module.action`، تُزرع بـ Seeder ولا يعدّلها المستخدم. أمثلة:
  `orders.view / create / update / cancel / refund`، `pos.discount / pos.price_override / pos.close_shift`، `customers.view / create / update / delete / export`، `services.manage`، `inventory.view / adjust / purchase`، `expenses.view / create / approve`، `employees.view / manage / payroll.view / payroll.run`، `reports.sales / reports.profit / reports.export`، `crm.send_messages / campaigns.manage`، `settings.manage`، `roles.manage`، `users.manage`.
- **Roles (أدوار):** **أدوار افتراضية** تُنسخ لكل مغسلة عند إنشائها (قابلة للتعديل): `Owner` (كل الصلاحيات، لا يمكن تقييده)، `Branch Manager`، `Cashier`، `Washer/Technician`، `Accountant`، `Inventory Keeper`، `Receptionist`. + **أدوار مخصّصة** ينشئها المالك (اسم + تحديد الصلاحيات من مصفوفة).
- **نطاق الصلاحية (Scope):** الدور يُمنح **لكل الفروع** أو **لفروع محددة** (`branch_user` + `role`)؛ فيرى مدير فرع A بيانات فرعه فقط. وهناك حدود للقيم (مثال: خصم الكاشير حتى 10% فقط، ما فوقه يحتاج موافقة المدير) عبر `role_limits`.
- **صلاحيات خاصة لمستخدم** (Direct permission override) نادرة الاستخدام: منح/سحب صلاحية فردية خارج الدور.
- **حماية:** لا يمكن حذف/تعديل دور Owner؛ لا يمكن للمستخدم منح صلاحية لا يملكها؛ يجب أن يبقى Owner واحد على الأقل.

**التنفيذ في Laravel:**
- حزمة `spatie/laravel-permission` مع **Teams** (team = `tenant_id`) فتكون الأدوار معزولة لكل مغسلة؛ جداول: `roles`, `permissions`, `model_has_roles`, `model_has_permissions`, `role_has_permissions` + `branch_user` للنطاق.
- فرض الصلاحيات في 3 طبقات: (1) `Route middleware` (`can:orders.create`)، (2) **Policies** لكل Model (تتحقق من الصلاحية + الفرع + ملكية السجل)، (3) فحص داخل الـ Actions للعمليات الحساسة (استرجاع، خصم، تعديل سعر، إقفال وردية).
- Endpoints إدارة: `GET /permissions` (الكتالوج مجمّعاً حسب الوحدة)، `CRUD /roles`، `PUT /roles/{id}/permissions`، `PUT /users/{id}/roles`، و`GET /me` يعيد الدور والصلاحيات والفروع المسموحة.
- كل تغيير في الأدوار/الصلاحيات يُسجَّل في Audit Log، ويُبطل كاش الصلاحيات فوراً.

**التنفيذ في Flutter:**
- عند الدخول يُحمَّل `GET /me` ويُخزَّن في Riverpod؛ `PermissionGuard` على المسارات (go_router redirect) + Widget `Can(permission: ..., child: ...)` لإخفاء الأزرار والقوائم غير المسموحة. (الإخفاء للتجربة فقط؛ **الخادم هو المرجع** ويرفض بـ 403).
- شاشات إدارة: قائمة الأدوار، **مصفوفة الصلاحيات** (وحدات × إجراءات بخانات اختيار)، إضافة موظف وتعيين دوره وفروعه، إيقاف/تفعيل حساب، إنهاء جلسات الأجهزة.
- القائمة الرئيسية والـ Dashboard تتكيف مع الدور (الكاشير يرى POS والطابور فقط؛ العامل يرى مهامه؛ المحاسب يرى المالية والتقارير).

**مثال مصفوفة افتراضية (مختصرة):**
| الصلاحية | Owner | Branch Mgr | Cashier | Washer | Accountant | Inventory |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| إنشاء/تعديل أمر عمل | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| تغيير حالة الأمر (مهامي) | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| خصم / تغيير سعر | ✅ | ✅ | حد أقصى | ❌ | ❌ | ❌ |
| استرجاع / إلغاء | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| المخزون (عرض/تعديل) | ✅ | ✅ | ❌ | ❌ | عرض | ✅ |
| المصاريف (إنشاء/اعتماد) | ✅ | إنشاء | ❌ | ❌ | ✅ | ❌ |
| الرواتب والتقارير المالية | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| إدارة الأدوار والموظفين | ✅ | موظفو فرعه | ❌ | ❌ | ❌ | ❌ |

### 2.4 المال
- تخزين المبالغ كأعداد صحيحة بالوحدة الصغرى (`bigint`، هللة/فلس) — لا `float` إطلاقاً. حزمة `brick/money` أو Value Object خاص.
- عملة وضريبة (VAT) وتنسيق لكل tenant. الفواتير **غير قابلة للتعديل** بعد الإصدار (تصحيح = إشعار دائن/استرجاع).
- كل حركة مالية تُسجَّل في `ledger_entries` (دفتر حركات مبسط، append-only) لضمان التطابق: مجموع المدفوعات = رصيد الصندوق.

---

## 3) الوحدات (Modules) ونطاق كل منها

1. **المنصة (SaaS):** tenants، خطط واشتراكات (Free/Basic/Pro)، حدود الفروع/المستخدمين، feature flags، فوترة الاشتراك، حالة الحساب (Active/Suspended).
2. **المستخدمون والأدوار والصلاحيات:** حسابات الموظفين، أدوار افتراضية ومخصّصة، مصفوفة صلاحيات قابلة للتعديل من التطبيق، نطاق حسب الفرع، حدود قيمية (مثل نسبة الخصم)، سجل دخول وأجهزة (انظر 2.3).
3. **الفروع والإعدادات:** بيانات الفرع، ساعات العمل، الأرصفة/المحطات (Bays)، الضرائب، قوالب الإيصال، العملة، اللغة.
4. **كتالوج الخدمات:** تصنيفات، خدمات (غسيل خارجي/داخلي/تلميع/تنظيف محرك…)، **سعر حسب حجم السيارة** (صغيرة/سيدان/SUV/شاحنة)، مدة متوقعة، إضافات (Add-ons)، باقات، **اشتراكات/عضويات شهرية** (غسلات مدفوعة مسبقاً)، عروض وكوبونات.
5. **العملاء والسيارات (CRM):** عميل (جوال، اسم، موافقة التواصل)، عدة سيارات لكل عميل (لوحة، ماركة، موديل، لون، حجم)، ملاحظات، وسوم، محفظة رصيد، نقاط ولاء، سجل الزيارات والإنفاق، تاريخ آخر زيارة.
6. **أوامر العمل (Orders / Work Orders) — قلب النظام:**
   - Check-in: اختيار السيارة، فحص حالة (صور/ملاحظات خدوش)، الخدمات، تعيين موظف/عدة موظفين ورصيف.
   - الحالات: `waiting → in_progress → qc → ready → delivered | cancelled`، مع طوابع زمنية لكل انتقال (لتحليل زمن الخدمة).
   - لوحة طابور مباشرة (WebSocket)، صور قبل/بعد، رابط تتبع عام للعميل (QR).
7. **الحجوزات والمواعيد:** مواعيد مسبقة، منع التعارض حسب الأرصفة والطاقة، تذكيرات.
8. **نقطة البيع والمدفوعات (POS):** نقدي/بطاقة/تحويل/محفظة/دفع مقسّم، خصومات، كوبونات، ضريبة، إيصال حراري + PDF، استرجاع، **إقفال الوردية** (جرد الصندوق: المتوقع مقابل الفعلي والفرق)، دفع إلكتروني (بوابة محلية حسب البلد: Moyasar/HyperPay/Tap/Stripe).
9. **المخزون والموارد:** أصناف (كيماويات، شامبو، مناشف، …)، وحدات، موردون، أوامر شراء، استلام، **حركات مخزون** (Append-only)، **استهلاك تلقائي لكل خدمة (وصفة BOM)**، حد أدنى وتنبيهات، جرد دوري، هدر.
10. **المعدات والأصول:** مضخات، ماكينات، مكانس؛ جدول صيانة دورية، سجل أعطال وتكلفة، إهلاك مبسط.
11. **الموظفون (HR):** ملفات، حضور وانصراف (+ GPS/PIN اختياري)، ورديات، **عمولات لكل خدمة** أو نسبة، سلف وخصومات، مسير رواتب شهري، إجازات، تقرير إنتاجية الموظف.
12. **المالية والمصاريف:** مصاريف مصنفة (إيجار، كهرباء، مياه، رواتب، صيانة…)، **مصاريف دورية** تُولَّد آلياً، مدفوعات الموردين والذمم (دائنة/مدينة)، حسابات الصندوق والبنك، تحويلات، **تقارير:** الأرباح والخسائر (P&L)، التدفق النقدي، الربحية لكل خدمة/فرع/موظف، نقطة التعادل، مقارنات شهرية.
13. **التواصل (CRM Messaging):** قوالب رسائل مترجمة، **محفزات تلقائية** (سيارتك جاهزة، تذكير موعد، شكر بعد الزيارة، تذكير غسلة، عيد ميلاد، استرجاع عميل غائب 30 يوماً)، حملات مستهدفة، قنوات: **واتساب (Cloud API عبر مزود رسمي) / SMS / Push**، احترام الموافقة وإلغاء الاشتراك، سجل الإرسال والتكلفة، استبيان رضا (NPS).
14. **التقارير ولوحات المؤشرات:** مبيعات يومية/شهرية، متوسط قيمة الفاتورة، الأكثر طلباً، ساعات الذروة، زمن الخدمة، أداء الموظفين، العملاء الجدد/المتكررين/المفقودين، تصدير Excel/PDF.
15. **أساسيات مشتركة:** سجل التدقيق (Audit Log لكل تعديل حساس)، إشعارات داخلية، نسخ احتياطي، رفع ملفات/صور، i18n.
16. **لاحقاً (غير MVP):** تطبيق العميل (حجز/تتبع/محفظة)، فاتورة إلكترونية (ZATCA وما يماثله) بنمط Adapter، لوحة KPIs متقدمة، تكامل كاميرات قراءة اللوحات (ANPR)، ربط المحاسبة.

---

## 4) تصميم قاعدة البيانات (الجداول الرئيسية)

> كل جدول تشغيلي: `id` UUID (v7)، `tenant_id`، `created_at/updated_at`، `deleted_at` (حيث يلزم).

- **المنصة:** `tenants`, `plans`, `subscriptions`, `subscription_invoices`
- **الهوية:** `users`, `roles`, `permissions`, `role_has_permissions`, `model_has_roles`, `model_has_permissions` (spatie، مع team = tenant)، `role_limits`, `personal_access_tokens`, `devices`, `branches`, `branch_user`, `bays`
- **الكتالوج:** `service_categories`, `services`, `service_prices` (service × vehicle_size × branch), `addons`, `packages`, `package_items`, `membership_plans`, `customer_memberships`, `coupons`
- **العملاء:** `customers`, `vehicles`, `customer_notes`, `loyalty_ledger`, `wallet_transactions`
- **العمليات:** `orders`, `order_items`, `order_assignments`, `order_status_history`, `order_photos`, `appointments`
- **المبيعات/المال:** `invoices`, `invoice_lines`, `payments`, `refunds`, `cash_shifts`, `cash_movements`, `accounts` (صندوق/بنك/…), `ledger_entries`, `expenses`, `expense_categories`, `recurring_expenses`, `suppliers`, `supplier_payments`
- **المخزون:** `inventory_items`, `stock_locations`, `stock_movements`, `service_consumptions` (BOM), `purchase_orders`, `purchase_order_lines`, `stock_counts`
- **الأصول:** `equipment`, `maintenance_schedules`, `maintenance_logs`
- **الموظفون:** `employees`, `attendance_logs`, `shifts`, `commission_rules`, `commission_entries`, `payroll_runs`, `payroll_lines`, `salary_advances`
- **التواصل:** `message_templates`, `message_logs`, `campaigns`, `campaign_recipients`, `feedback`
- **عام:** `audit_logs`, `settings`, `media`, `idempotency_keys`

**قواعد:** فهارس `(tenant_id, branch_id, created_at)` للتقارير؛ حركات المخزون والمال **append-only** (التصحيح بقيد عكسي)؛ ترقيم الفواتير متسلسل لكل فرع ويُولَّد من الخادم داخل Transaction.

---

## 5) الاتصال بالخادم (Online-only)

النظام يعمل **أونلاين فقط** (قرار معتمد: لا أوفلاين ولا مزامنة). لضمان الموثوقية:
- **Idempotency-Key** على عمليات الدفع وإنشاء الأوامر لمنع التكرار عند إعادة المحاولة بسبب ضعف الشبكة (جدول `idempotency_keys` على الخادم).
- معالجة أخطاء الشبكة في التطبيق: إعادة محاولة تلقائية محدودة، رسائل واضحة، ومنع الضغط المزدوج على زر الدفع.
- كاش خفيف في الذاكرة للكتالوج والإعدادات لتسريع الواجهة فقط (بدون قاعدة محلية).

---

## 6) تصميم الـ API (Laravel)

- بنية: `app/Domain/{Orders,Billing,Inventory,Hr,Finance,Crm,Platform}/` تحتوي Models + Actions (حالة استخدام واحدة لكل Action) + Policies + Events؛ وطبقة `app/Http/{Controllers/Api/V1,Requests,Resources}`.
- REST `/api/v1/...`، ترقيم Cursor، ترشيح وفرز موحّد، أخطاء بصيغة موحدة (RFC 7807).
- توثيق OpenAPI تلقائي بـ **dedoc/scramble** → يمكن توليد عميل Dart منه لتقليل الأخطاء.
- العمليات الثقيلة (إرسال رسائل، تقارير، مسير الرواتب، مصاريف دورية) عبر **Queues** (driver قاعدة البيانات حالياً، ويُنقل إلى Redis + Horizon عند النمو) و**Scheduler**.
- الوقت الحقيقي (لوحة الطابور، إشعارات) عبر **Laravel Reverb**.
- Rate limiting، Form Requests لكل مدخل، Policies لكل Model، Transactions + `lockForUpdate` للمخزون والصندوق.

**حزم Laravel المقترحة:** `laravel/sanctum`, `spatie/laravel-permission`, `spatie/laravel-activitylog`, `spatie/laravel-medialibrary`, `laravel/horizon`, `laravel/reverb`, `dedoc/scramble`, `filament/filament`, `maatwebsite/excel`, `barryvdh/laravel-dompdf`, `brick/money`، اختبارات بـ PHPUnit (المثبّت حالياً) + `laravel/pint`.

---

## 7) تطبيق Flutter

- **الهيكل:** Feature-first + Clean architecture خفيفة: `lib/features/{auth,orders,pos,customers,inventory,hr,finance,crm,reports,settings}/{data,domain,presentation}` + `core/{network,l10n,theme,printing}`. المجلد المقترح: `carwash/mobile/`.
- **الحزم:** `flutter_riverpod` (+ riverpod_generator)، `go_router`، `dio`، `freezed`/`json_serializable`، `flutter_secure_storage`، `flutter_localizations` + ARB (ar/en، RTL تلقائي)، `firebase_messaging`، `mobile_scanner` (QR/باركود)، `image_picker` + ضغط الصور، `print_bluetooth_thermal`/`esc_pos_utils_plus` (طابعة حرارية)، `pdf`/`printing`، `fl_chart`، `laravel_reverb`/`web_socket_channel`.
- **واجهة متجاوبة:** هاتف (عامل: قائمة مهام) · تابلت (كاشير: POS + طابور) · ويب (مالك: لوحات وجداول). نفس الكود بـ `LayoutBuilder` وBreakpoints.
- **مظهر:** Material 3، خط عربي (Cairo/IBM Plex Sans Arabic)، وضع داكن.
- **Flavors:** `dev / staging / prod`، CI (GitHub Actions + Codemagic للـ iOS).

---

## 8) الأمن والامتثال
- عزل بيانات tenants (Scope + اختبارات + فحص في الـ Policies)، تشفير الأسرار (مفاتيح البوابات) بـ `encrypted` casts، HTTPS فقط، تدوير tokens، قفل الجهاز بالـ PIN.
- Audit Log لكل تعديل مالي/صلاحيات/أسعار/استرجاع.
- موافقة العميل على الرسائل التسويقية وحق الحذف (PDPL/GDPR)، تفعيل قوالب واتساب المعتمدة من Meta.
- نسخ احتياطي يومي (DB + الملفات) واختبار استرجاع، مراقبة (Sentry + Laravel Pail/Telescope في dev).

---

## 9) خارطة الطريق (تقديرية لمطوّر/مطوّرَين)

| المرحلة | المحتوى | المدة |
|---|---|---|
| **0 – الأساس** | إعداد WSL/PHP/Flutter، Laravel + MySQL، Multi-tenancy، Auth + **نظام الأدوار والصلاحيات (Permission Catalog، الأدوار الافتراضية، Policies، شاشات الإدارة)**، CI، هيكل Flutter + i18n | 2 أسبوع |
| **1 – MVP تشغيلي** | الفروع، كتالوج الخدمات، العملاء/السيارات، أوامر العمل + الطابور، POS نقدي، إيصال حراري، إقفال الوردية، تقرير يومي | 6–8 أسابيع |
| **2 – الموارد والمال** | المخزون + استهلاك الخدمات، الموردون، المصاريف الدورية، الموظفون + الحضور + العمولات + الرواتب، P&L والتدفق النقدي | 6–8 أسابيع |
| **3 – التواصل والدفع** | واتساب/SMS/Push + المحفزات والحملات، الدفع الإلكتروني، الحجوزات | 6–8 أسابيع |
| **4 – SaaS والإطلاق** | لوحة Filament للمشغّل، الخطط والاشتراكات، Onboarding للمغاسل، المراقبة، النسخ، النشر على Play/App Store | 4–6 أسابيع |
| **5 – لاحقاً** | تطبيق العميل، الفاتورة الإلكترونية (ZATCA…)، ANPR، تكاملات محاسبية | حسب الطلب |

> يُنصح بإطلاق نسخة تجريبية (Pilot) على مغسلة حقيقية بعد المرحلة 1 لجمع الملاحظات مبكراً.

---

## 10) التحقق (Verification)
- **Backend:** `php artisan test` — اختبارات: عزل الـ tenant لكل endpoint، **مصفوفة الصلاحيات (كل دور × كل endpoint حساس: 200 للمسموح و403 لغيره)، نطاق الفرع، حدود الخصم، حماية دور Owner**، منطق التسعير/الضريبة/الخصم، تطابق الصندوق (مجموع الدفعات = حركة الصندوق)، استهلاك المخزون، Idempotency للدفع وإنشاء الأوامر، توليد المصاريف الدورية.
- **Flutter:** unit tests للـ repositories، widget tests للـ POS، integration test لسيناريو: (تسجيل دخول → إنشاء أمر عمل → دفع → إيصال، مع إعادة إرسال نفس طلب الدفع والتحقق أنه سُجّل مرة واحدة).
- **يدوي:** تشغيل على جهاز Android + طابعة حرارية حقيقية، تجربة RTL/LTR، اختبار حمل بسيط (k6) على endpoints الطابور والـ POS.

---

## بيئة التطوير الحالية
- **مسار المشروع:** `C:\xampp\htdocs\carwash` (نُسخ من WSL؛ نسخة WSL القديمة لم تعد مرجعاً).
- **PHP:** `C:\xampp\php84\php.exe` (8.4.27، بجانب PHP 8.2 الخاص بـ XAMPP). **Composer:** `C:\xampp\php84\composer.phar`. الأوامر: `php artisan ...` (المسار مضاف لـ PATH، يعمل في طرفية جديدة).
- **قاعدة البيانات:** **MySQL 8.4.13 LTS** في `C:\xampp\mysql` (حلّت محل MariaDB الخاصة بـ XAMPP، والنسخة القديمة محفوظة في `C:\xampp\mysql_mariadb104`) على `127.0.0.1:3307`، الإعداد في `C:\xampp\mysql\bin\my.ini` (utf8mb4، mysqlx معطّل). تُشغَّل من زر MySQL في لوحة XAMPP. قاعدة `carwash` + `carwash_testing` للاختبارات، المستخدم `admin` (كلمة السر في `.env`)، و`root` بدون كلمة سر محلياً. الإدارة عبر **phpMyAdmin** على http://localhost/phpmyadmin.
- **التشغيل:** `php artisan serve` على http://localhost:8000. Git for Windows 2.56 مثبّت ومضبوط (user: Ali، الفرع الافتراضي `main`، مستودع مهيّأ في `C:\xampp\htdocs\carwash` بدون commits بعد؛ `.env` و`vendor` مستثنيان في `.gitignore`).
- **الاختبارات:** `php artisan test` على MySQL (`carwash_testing`) لأن PHP 8.4 هنا بدون `pdo_sqlite`، ولتطابق بيئة الإنتاج.
- **ملاحظة:** إن لم يُعرف `php` أو `git` في طرفية VS Code، أعد تشغيل VS Code (أُضيفت للـ PATH بعد فتحه).

## (C) سجل القرارات (ADR)
| التاريخ | القرار | السبب |
|---|---|---|
| 2026-10-24 | Flutter رئيسي + Filament للمشغّل فقط | الطباعة والموبايل والأدوار؛ سرعة لوحة المشغّل |
| 2026-10-24 | Multi-tenant بقاعدة واحدة و`tenant_id` | بساطة التشغيل والتقارير والتكلفة |
| 2026-10-24 | أونلاين فقط (بدون أوفلاين) | تقليل التعقيد؛ قرار المالك |
| 2026-10-24 | RBAC بـ spatie/permission مع Teams وأدوار مخصّصة | تحكم المالك بالصلاحيات دون مطوّر |
| 2026-10-24 | MySQL 8 (عبر XAMPP) بدل PostgreSQL، والـ queue/cache على DB بدل Redis | بيئة المالك؛ أبسط للتطوير. الانتقال لـ Redis لاحقاً بتغيير `.env` فقط |
| 2026-10-24 | MySQL 8.4.13 LTS حقيقية بدل MariaDB 10.4 المرفقة مع XAMPP، مع phpMyAdmin | طلب المالك؛ تطابق الإنتاج ودعم UUID/JSON الحديث |
| 2026-10-24 | المفاتيح UUID (v7 عبر `HasUuids`) للمستخدمين وكل الجداول التشغيلية، وأعمدة morph في Sanctum/permission/activitylog/media بصيغة UUID | تطبيق القسم 4 قبل وجود بيانات؛ لا يمكن تغييره لاحقاً بسهولة |
| 2026-10-24 | spatie/permission Teams بمفتاح `tenant_id` (UUID) | عزل الأدوار لكل مغسلة |
| 2026-10-24 | `TenantScope` يفشل بإغلاق (Fail-closed): أي استعلام على بيانات tenant بدون tenant حالي يرمي `TenancyException` بدل إرجاع كل البيانات؛ والتجاوز صريح فقط (`withoutGlobalScope`) | منع تسريب البيانات بالخطأ في الـ jobs والأوامر والمسارات العامة |
| 2026-10-24 | الـ tenant الحالي يُضبط من المستخدم المصادَق في middleware ضمن مجموعة `api`، بأولوية بعد المصادقة وقبل Route Model Binding؛ ويضبط معه `setPermissionsTeamId` | لا يُقبل tenant من الطلب أبداً؛ والـ binding لا يجد سجلات tenant آخر (404 وليس 403) |
| 2026-10-24 | `users` غير مُقيَّد بـ Global Scope (له `tenant_id` nullable لمشغّلي المنصة) | المصادقة تحتاج إيجاد المستخدم قبل معرفة الـ tenant؛ استعلامات قوائم المستخدمين تُقيَّد صراحةً |
| 2026-10-24 | كود المنصة في `app/Domain/Platform/{Models,Enums,Tenancy}` والمصانع في `database/factories` عبر `#[UseFactory]` | تطبيق بنية القسم 6 |
| 2026-10-24 | الاختبارات على قاعدة MySQL مستقلة `carwash_testing` بدل SQLite | لا يوجد `pdo_sqlite`، وسلوك MySQL (فهارس، أقفال) يجب أن يُختبر فعلياً |

## (D) سجل التغييرات (Changelog)
- **2026-10-24:** إنشاء الخطة الأولية، إضافة نظام الأدوار والصلاحيات، حذف الأوفلاين، إنشاء هذا الملف، اعتماد MySQL بدل PostgreSQL.
- **2026-10-24:** تثبيت MySQL 8.4.13 مكان MariaDB في XAMPP؛ تثبيت Laravel Boost؛ تثبيت Sanctum (`install:api`) وspatie/permission (Teams=`tenant_id`) وactivitylog وmedialibrary وscramble؛ تحويل `users` إلى UUID؛ نقل الاختبارات إلى `carwash_testing`؛ إضافة `UserIdentityTest` (UUID، توكن Sanctum، عزل الأدوار بين tenants).
- **2026-10-24:** Multi-tenancy: جداول `tenants` (الحالة، اللغة، العملة، المنطقة الزمنية) و`branches` و`users.tenant_id` وربط جداول الصلاحيات بـ `tenants`؛ `BelongsToTenant` يملأ `tenant_id` تلقائياً ويمنع الكتابة لـ tenant آخر أو نقل السجل؛ رفض مستخدمي المغاسل الموقوفة والمستخدمين بلا tenant بـ 403؛ Seeder لمغسلة تجريبية؛ 15 اختباراً جديداً (`TenantIsolationTest` و`TenantApiIsolationTest`).

## (E) المخاطر المفتوحة والأسئلة المعلّقة
- [ ] تحديد البلد/العملة/الضريبة (يؤثر على بوابة الدفع والفاتورة الإلكترونية ومزود SMS/واتساب).
- [ ] اختيار مزوّد واتساب الرسمي (Meta Cloud API مباشرة أو BSP).
- [ ] توفير جهاز Mac أو CI سحابي لبناء iOS، وحساب Apple Developer.
- [ ] اختيار الاستضافة (VPS / سحابة) لـ Laravel وMySQL (وRedis لاحقاً).
