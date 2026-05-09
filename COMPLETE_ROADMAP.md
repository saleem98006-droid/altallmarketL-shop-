# 📋 Roadmap التحويل الكامل

## المرحلة 0: ✅ تم الإنجاز (30% مكتمل)

### الملفات المُحولة:
- ✅ `lib/main.dart`
- ✅ `lib/providers/account_provider.dart` - تحويل كامل إلى Riverpod
- ✅ `lib/providers/router_provider.dart` - ملف جديد بـ 25+ route
- ✅ `lib/screens/splash_screen.dart`
- ✅ `lib/screens/home_screen.dart`
- ✅ `lib/screens/options/options_tab.dart`
- ✅ `lib/core/notification_helper_router.dart` - ملف جديد

### التحديثات العامة:
- ✅ `pubspec.yaml` - إضافة Riverpod و GoRouter
- ✅ 4 ملفات توثيق شاملة

---

## المرحلة 1: Auth Screens (الأولوية العالية)

**الملفات:** 6 ملفات | **الوقت المتوقع:** 45 دقيقة

### 1. `lib/screens/myAccount/login_screen.dart`
- [ ] إضافة `import 'package:flutter_riverpod/flutter_riverpod.dart'`
- [ ] إضافة `import 'package:go_router/go_router.dart'`
- [ ] تحويل إلى `ConsumerStatefulWidget`
- [ ] استبدال جميع `Navigator.pushNamed()` بـ `context.go()`
- [ ] استبدال `Navigator.pushReplacementNamed()` بـ `context.go()`

### 2. `lib/screens/myAccount/signup_step1.dart`
- [ ] نفس الخطوات أعلاه

### 3. `lib/screens/myAccount/signup_step2.dart`
- [ ] نفس الخطوات أعلاه

### 4. `lib/screens/myAccount/signup_step3.dart`
- [ ] نفس الخطوات أعلاه

### 5. `lib/screens/myAccount/signup_step4.dart`
- [ ] تحويل إلى `ConsumerStatefulWidget`
- [ ] استبدال جميع Navigator calls

### 6. `lib/screens/myAccount/inactive_screen.dart`
- [ ] تحويل إلى `ConsumerWidget`
- [ ] استبدال `Consumer<AccountProvider>` بـ `ref.watch(accountProvider)`
- [ ] استبدال Navigator calls بـ GoRouter

---

## المرحلة 2: Detail Screens (الأولوية العالية)

**الملفات:** 4 ملفات | **الوقت المتوقع:** 30 دقيقة

### 1. `lib/screens/product_detail_screen.dart`
- [ ] تحويل إلى `ConsumerWidget` أو `ConsumerStatefulWidget`
- [ ] استبدال جميع `Navigator.*` بـ `context.*`
- [ ] تحديث أي `Consumer<T>` بـ `ref.watch()`

### 2. `lib/screens/edit_product_screen.dart`
- [ ] نفس الخطوات أعلاه

### 3. `lib/screens/offer_detail_screen.dart`
- [ ] نفس الخطوات أعلاه

### 4. `lib/screens/edit_slider_screen.dart`
- [ ] نفس الخطوات أعلاه

---

## المرحلة 3: Options & Management Screens

**الملفات:** 14 ملف | **الوقت المتوقع:** 1.5 ساعة

### Add Screens (4 ملفات)
- [ ] `lib/screens/options/add_product_screen.dart`
- [ ] `lib/screens/options/add_offer_screen.dart`
- [ ] `lib/screens/options/add_discount_screen.dart`
- [ ] `lib/screens/options/add_section_screen.dart`

### Management Screens (5 ملفات)
- [ ] `lib/screens/options/price_adjustment_screen.dart`
- [ ] `lib/screens/options/customer_withdrawals_screen.dart`
- [ ] `lib/screens/options/customer_withdrawals_details_screen.dart`
- [ ] `lib/screens/options/job_vacancies_screen.dart`
- [ ] `lib/screens/options/add_job_vacancy_screen.dart`

### Misc Screens (5 ملفات)
- [ ] `lib/screens/options/edit_job_vacancy_screen.dart`
- [ ] `lib/screens/options/complaints_screen.dart`
- [ ] `lib/screens/options/suggestions_screen.dart`
- [ ] `lib/screens/options/about_screen.dart`
- [ ] `lib/screens/options/add_slider_screen.dart`

---

## المرحلة 4: Tabs و Support Screens

**الملفات:** 6 ملفات | **الوقت المتوقع:** 45 دقيقة

### Account Management (2 ملف)
- [ ] `lib/screens/myAccount/update_account_screen.dart`
- [ ] `lib/screens/myAccount/accepted_screen.dart`

### Tabs & Components (4 ملفات)
- [ ] `lib/screens/home/home_tab.dart` - قد تحتاج تعديلات
- [ ] `lib/screens/orders/orders_tab.dart` - قد تحتاج تعديلات
- [ ] `lib/screens/notifications/notifications_page.dart`
- [ ] `lib/screens/new_order_tab.dart`

---

## المرحلة 5: Testing و Optimization

**الوقت المتوقع:** 2 ساعة

### Unit Tests
- [ ] كتابة tests للـ `accountProvider`
- [ ] كتابة tests للـ router navigation

### Integration Tests
- [ ] اختبار الـ navigation flows
- [ ] اختبار الإشعارات
- [ ] اختبار state persistence

### Performance Testing
- [ ] قياس startup time
- [ ] قياس memory usage
- [ ] تحليل rendering performance

### Bug Fixes
- [ ] إصلاح أي bugs تظهر أثناء الاختبار
- [ ] تحسين UX issues

---

## ملخص الترتيب

```
┌─────────────────────────────────────┐
│    Phase 0: Foundation (Done) ✅    │
│    - Main setup & Core providers    │
│    - Riverpod & GoRouter config     │
│    - 3 base screens updated         │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Phase 1: Auth Screens (Priority 1) │  
│    6 files | 45 min                 │
│    - Login & Signup flows           │
│    - Inactive screen                │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ Phase 2: Detail Screens (Priority 1)│
│    4 files | 30 min                 │
│    - Product/Offer details          │
│    - Edit screens                   │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ Phase 3: Management Screens (P2)    │
│    14 files | 1.5 hours             │
│    - Add/Edit/Delete operations     │
│    - Configuration screens          │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ Phase 4: Misc Screens (Priority 2)  │
│    6 files | 45 min                 │
│    - Tabs & support screens         │
│    - Notifications                  │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Phase 5: Testing & Optimization    │
│    2 hours                          │
│    - Unit & Integration tests       │
│    - Performance optimization       │
│    - Bug fixes                      │
└─────────────────────────────────────┘
```

---

## إحصائيات

| المرحلة | الملفات | الوقت | الأولوية |
|--------|--------|-------|---------|
| 0 | 7 | تم | عالي ✅ |
| 1 | 6 | 45 دقيقة | عالي 🔴 |
| 2 | 4 | 30 دقيقة | عالي 🔴 |
| 3 | 14 | 1.5 ساعة | متوسط 🟡 |
| 4 | 6 | 45 دقيقة | متوسط 🟡 |
| 5 | - | 2 ساعة | متوسط 🟡 |
| **المجموع** | **37** | **~5 ساعات** | - |

---

## نصائح سريعة لتسريع العملية

### 1. استخدم Find & Replace
```
Find:    Navigator.pushNamed\(context, '([^']+)'\)
Replace: context.go('$1')
```

### 2. استخدم Templates
- انسخ من ملف تم تحويله بالفعل
- غيّر البيانات الخاصة به

### 3. قسّم العمل
- اعمل على 2-3 ملفات دفعة واحدة
- اختبر بعد كل دفعة

### 4. استخدم Grep للبحث
```bash
grep -r "Navigator.pushNamed" lib/screens/ | grep -v "lib/screens/myAccount/login_screen"
```

---

## متطلبات الإنجاز

✅ **الحد الأدنى (Phase 0-2):**
- تطبيق يعمل بشكل أساسي
- معظم flows تعمل
- جاهز للاختبار الأولي

✅ **الإكمال الكامل (Phase 0-5):**
- تطبيق كامل الأداء
- جميع features تعمل
- معايير quality عالية
- جاهز للإطلاق

---

## الخطوة التالية

1. ابدأ بـ Phase 1 (Auth Screens)
2. استخدم الـ Templates من `MIGRATION_TEMPLATES.md`
3. اختبر كل ملف بعد التحويل
4. اشتغل على Phase 2
5. ثم الباقي حسب الأولوية

---

**آخر تحديث:** 2026-04-07  
**الحالة:** 🟢 جاهز للمرحلة 1
