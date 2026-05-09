# دليل سريع - نقل المشروع إلى Riverpod 2 و GoRouter

## 🚀 البدء السريع

تم نقل مشروع TM Shop من `Provider` و `Navigator` القديمة إلى `Riverpod 2` و `GoRouter` الحديثة.

### قم بتشغيل الأوامر التالية:

```bash
# 1. تحديث الحزم
flutter pub get

# 2. تنظيف المشروع (اختياري لكن موصى به)
flutter clean

# 3. تشغيل التطبيق
flutter run -v
```

---

## 🔧 التغييرات الرئيسية

### ✅ تم تطويره:

1. **Riverpod State Management**
   - `accountProvider` - إدارة حالة الحساب
   - دعم كامل للـ `StateNotifier` و `ConsumerWidget`

2. **GoRouter Navigation**
   - جميع 25+ شاشة معرفة في `router_provider.dart`
   - دعم route parameters و query parameters
   - handling للإشعارات

3. **Firebase Notifications**
   - جميع handlers محفوظة
   - integration جديد مع GoRouter

### ⏳ يحتاج إلى تطوير:

الملفات التالية تحتاج إلى تحديث إضافي:
- `login_screen.dart`
- `signup_step1-4.dart`
- `inactive_screen.dart`
- جميع `detail_screens`
- باقي `options` screens

---

## 💡 أمثلة الاستخدام

### الذهاب إلى شاشة

```dart
// بدل: Navigator.pushNamed(context, '/home')
context.go('/home');

// مع parameters
context.go('/edit-product/123');

// مع query parameters
context.go('/home?tab=1');
```

### قراءة حالة الحساب

```dart
// في ConsumerWidget أو ConsumerStatefulWidget:
final accountState = ref.watch(accountProvider);
print(accountState.isActive); // true/false
print(accountState.isAccepted); // true/false
print(accountState.deliveryType); // string
```

### تحديث حالة الحساب

```dart
// تحديث قيمة
await ref.read(accountProvider.notifier).setActive(false);

// إعادة تعيين
await ref.read(accountProvider.notifier).reset();
```

### Back Navigation

```dart
// بدل: Navigator.pop(context)
context.pop();

// أو إعادة توجيه مباشرة
context.go('/home');
```

---

## 🐛 استكشاف الأخطاء

### خطأ: "Provider not found"
→ تأكد من أن `ProviderScope` موجود في `MyApp`

### خطأ: "Navigator not available"
→ استخدم `context.go()` فقط بدل `Navigator.pushNamed()`

### خطأ: "Can't access ref in StatelessWidget"
→ غيّر إلى `ConsumerWidget` أو `ConsumerStatefulWidget`

---

## 📚 ملفات الدليل

- [`RIVERPOD_MIGRATION.md`](./RIVERPOD_MIGRATION.md) - دليل كامل للترحيل
- [`lib/providers/router_provider.dart`](./lib/providers/router_provider.dart) - تعريف جميع routes
- [`lib/providers/account_provider.dart`](./lib/providers/account_provider.dart) - state management

---

## ✨ الفوائد

✅ **أفضل إدارة للحالة** - Riverpod أكثر كفاءة من Provider  
✅ **navigation أنظف** - GoRouter أقوى من Navigator القديمة  
✅ **أداء أفضل** - أقل عدد من عمليات rebuild  
✅ **كود أسهل للصيانة** - توثيق أفضل وأنماط معروفة  

---

**آخر تحديث:** 2026-04-07
