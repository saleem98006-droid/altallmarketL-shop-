# 🚀 أوامر سريعة - Riverpod و GoRouter Migration

## البدء الفوري

```bash
# خطوة 1: تحديث الحزم
flutter pub get

# خطوة 2: تنظيف (مهم!)
flutter clean

# خطوة 3: تشغيل التطبيق
flutter run -v
```

---

## أوامر مفيدة أثناء التطوير

### تشغيل التطبيق
```bash
# تشغيل عادي
flutter run

# تشغيل مع logs تفصيلية
flutter run -v

# تشغيل على جهاز محدد
flutter run -d <device_id>

# عرض أجهزة متاحة
flutter devices
```

### البناء و التجميع
```bash
# بناء APK للإصدار
flutter build apk --release

# بناء AAB (Google Play)
flutter build appbundle --release

# بناء iOS
flutter build ios --release
```

### الصيانة و التنظيف
```bash
# تنظيف شامل
flutter clean

# حذف الملفات المؤقتة
rm -rf build/
rm -rf .dart_tool/

# إعادة تثبيت الحزم
flutter pub get

# تحديث جميع الحزم
flutter pub upgrade
```

---

## استكشاف الأخطاء

### مشكلة: "Unresolved reference: 'context.go'"

**الحل:**
```dart
import 'package:go_router/go_router.dart';
```

### مشكلة: "Provider not found"

**الحل:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// تأكد من ProviderScope في main.dart
runApp(
  const ProviderScope(
    child: MyApp(),
  ),
);
```

### مشكلة: "Navigator is deprecated"

**الحل:** استخدم `context.go()` أو `context.push()` بدل Navigator

### مشكلة: "Can't use ref in StatelessWidget"

**الحل:** غيّر إلى `ConsumerWidget`
```dart
class MyScreen extends ConsumerWidget {  // ✅ بدل StatelessWidget
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الآن يمكنك استخدام ref
  }
}
```

---

## Find & Replace الذكية

### في VS Code

#### استبدال Navigator.pushNamed
```
Find:    Navigator.pushNamed\(context, '([^']+)'\)
Replace: context.go('$1')
Enable Regex
```

#### استبدال Consumer<T>
```
Find:    Consumer<([^>]+)>\s*\(\s*builder: \(context, (\w+), child\) =>
Replace: final $2 = ref.watch($1Provider);\n    
Enable Regex
```

#### استبدال Provider.of
```
Find:    Provider\.of<([^>]+)>\(context, listen: false\)
Replace: ref.read($1Provider.notifier)
Enable Regex
```

---

## اختبار سريع

```bash
# تشغيل tests
flutter test

# تشغيل test واحد
flutter test test/unit/account_provider_test.dart

# تشغيل مع coverage
flutter test --coverage
```

---

## حل مشاكل الأداء

```bash
# قياس الأداء
flutter run --profile

# تحليل الذاكرة
devtools

# معلومات التطبيق
flutter doctor -v
```

---

## أوامر مسح الـ Cache

```bash
# مسح بيانات التطبيق على الجهاز
flutter clean
flutter pub get

# إزالة التطبيق من الجهاز
adb uninstall com.altall.market.shop

# إعادة تثبيت كامل
flutter clean && flutter pub get && flutter run
```

---

## نصائح للسرعة

### استخدم make أو bash script

```bash
#!/bin/bash
echo "🧹 Cleaning..."
flutter clean

echo "📦 Getting packages..."
flutter pub get

echo "🚀 Running app..."
flutter run -v
```

احفظ هذا بـ `run.sh` واستخدمه:
```bash
chmod +x run.sh
./run.sh
```

---

## ملاحظات مهمة

### عند التطوير
- ✅ استخدم `Hot Restart` (Shift + Cmd + R) وليس Hot Reload
- ✅ تحقق من الـ logs دائماً عند حدوث مشاكل
- ✅ استخدم `flutter doctor -v` للتحقق من البيئة

### عند الإنتاج
- ✅ استخدم `--release` flag
- ✅ اختبر على جهاز حقيقي
- ✅ تحقق من الـ logs قبل الإطلاق

---

## Links مفيدة

- 📚 [Riverpod Docs](https://riverpod.dev)
- 🗺️ [GoRouter Docs](https://pub.dev/packages/go_router)
- 🎯 [Flutter Nav Best Practices](https://flutter.dev/docs/development/ui/navigation)
- 🐛 [Flutter Debugging](https://flutter.dev/docs/testing/debugging)

---

**آخر تحديث:** 2026-04-07
