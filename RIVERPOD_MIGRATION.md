# مشروع TM Shop - ترحيل إلى Riverpod 2 و GoRouter

## ✅ التغييرات المُنفذة

### 1. **pubspec.yaml**
تم إضافة الحزم التالية:
- `riverpod: ^2.6.1`
- `flutter_riverpod: ^2.6.1`
- `go_router: ^14.2.0`
- `build_runner: ^2.4.12`
- `riverpod_generator: ^2.4.2`

تم إزالة:
- `provider: ^6.1.2`

### 2. **lib/providers/account_provider.dart**
تحويل كامل من `Provider` القديم إلى `Riverpod 2`:
- تم إنشاء `AccountState` class
- تم إنشاء `AccountNotifier` extends `StateNotifier<AccountState>`
- تم إنشاء `accountProvider` كـ `StateNotifierProvider`
- الحفاظ على نفس الوظائف: `loadFromStorage()`, `setActive()`, `setAccepted()`, `setDeliveryType()`, `reset()`

### 3. **lib/providers/router_provider.dart** (ملف جديد)
تم إنشاء ملف شامل لجميع الـ Routes:
- `AppRoutes` class يحتوي على جميع route names
- `goRouterProvider` - GoRouter configuration
- تعريف جميع 25+ شاشة مع paths و parameters
- دعم navigation بـ query parameters (مثل tab selection)

### 4. **lib/main.dart**
تم استبدال الكود بالكامل:
- استخدام `ProviderScope` لتوفير Riverpod
- تغيير `MyApp` إلى `ConsumerStatefulWidget`
- استخدام `MaterialApp.router` بدل `MaterialApp`
- تفعيل `goRouterProvider` من Riverpod
- الحفاظ على جميع Firebase و Notifications handlers

### 5. **lib/core/notification_helper_router.dart** (ملف جديد)
- دالة `navigateByNotificationRouter()` للتعامل مع إشعارات مع GoRouter
- دعم جميع scenarios: tab navigation, account status changes, details screens

### 6. **lib/screens/splash_screen.dart**
- تحديث جميع `Navigator.pushReplacementNamed()` إلى `context.go()`
- إضافة import لـ `GoRouter` و `AppRoutes`

### 7. **lib/screens/home_screen.dart**
- تحويل إلى `ConsumerStatefulWidget`
- استخدام `ref.watch(accountProvider)` بدل `Consumer<AccountProvider>`
- تحديث navigation إلى `context.go()` بدل `Navigator.pushReplacementNamed()`

### 8. **lib/screens/options/options_tab.dart**
- تحويل إلى `ConsumerStatefulWidget`
- استبدال `Provider.of<AccountProvider>().reset()` بـ `ref.read(accountProvider.notifier).reset()`
- تحديث جميع `Navigator.pushNamed()` إلى `context.go()`

---

## 🛠️ الخطوات التالية المطلوبة

### 1. **تحديث باقي الملفات**
الملفات التالية تحتاج إلى تحديث ولم يتم تعديلها بعد:

**ملفات Auth:**
- `lib/screens/myAccount/login_screen.dart` - استبدال Navigator
- `lib/screens/myAccount/signup_step1.dart` - استبدال Navigator
- `lib/screens/myAccount/signup_step2.dart` - استبدال Navigator
- `lib/screens/myAccount/signup_step3.dart` - استبدال Navigator
- `lib/screens/myAccount/signup_step4.dart` - تحويل إلى ConsumerWidget + استبدال Navigator
- `lib/screens/myAccount/inactive_screen.dart` - تحويل Consumer<AccountProvider> إلى ref.watch

**ملفات التفاصيل:**
- `lib/screens/product_detail_screen.dart`
- `lib/screens/edit_product_screen.dart`
- `lib/screens/offer_detail_screen.dart`
- `lib/screens/edit_slider_screen.dart`

**ملفات الخيارات:**
- `lib/screens/options/*.dart` - استبدال جميع Navigator calls

### 2. **تشغيل التطبيق**

```bash
# تحديث الحزم
flutter pub get

# إعادة بناء الحزم المولدة (إذا تم استخدام riverpod_generator لاحقاً)
flutter pub run build_runner build

# تشغيل التطبيق
flutter run
```

### 3. **تصحيح الأخطاء**

قد تظهر أخطاء تحتاج إلى:
- البحث عن `Navigator.push` و `Navigator.pop` و `Navigator.pushNamed` في جميع الملفات
- استبدالها بـ `context.go()` أو `context.push()` أو `context.pop()`
- تحويل أي widget يستخدم `Consumer<AccountProvider>` إلى `ref.watch(accountProvider)`

### 4. **التعديل على Router Paths**

إذا احتجت لتمرير parameters أكثر تعقيداً:

```dart
// بدل:
Navigator.pushNamed(context, '/editProduct', arguments: {'product': product});

// استخدم:
context.go('/edit-product/${product.id}');

// أو بـ query parameters:
context.go('/edit-product/${product.id}?name=${product.name}');
```

### 5. **إعادة صياغة Notification Navigation**

في ملف `lib/main.dart`، استخدم `handleNotificationNavigation()` الجديد:

```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  final screen = message.data['screen'] ?? "";
  handleNotificationNavigation(
    screen: screen,
    data: message.data,
  );
});
```

---

## 📋 قائمة التحقق

- [x] تحديث pubspec.yaml
- [x] تحويل AccountProvider إلى Riverpod
- [x] إنشاء RouterProvider الشامل
- [x] تحديث main.dart
- [x] إنشاء notification_helper_router.dart
- [x] تحديث splash_screen.dart
- [x] تحديث home_screen.dart
- [x] تحديث options_tab.dart
- [ ] تحديث باقي auth screens
- [ ] تحديث باقي detail screens
- [ ] تحديث جميع ملفات الخيارات
- [ ] اختبار شامل للتطبيق
- [ ] اختبار الإشعارات والتنقل

---

## 🔗 مراجع مفيدة

- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Flutter Navigation Patterns](https://flutter.dev/docs/development/ui/navigation)

---

## ⚠️ ملاحظات مهمة

1. **لا تنسَ Hot Restart**: عند تجربة التطبيق، استخدم "Hot Restart" وليس "Hot Reload"
2. **تنظيف الـ Build**: قد تحتاج إلى `flutter clean` إذا ظهرت مشاكل غريبة
3. **الحفاظ على Firebase**: جميع Firebase handlers و Notifications تم الحفاظ عليها كما هي
4. **الإرث**: الكود القديم (navigation_helper.dart) لا يزال في المشروع للرجوع إليه إذا لزم

---

آخر تحديث: **2026-04-07**
