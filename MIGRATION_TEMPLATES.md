# قالب تحويل الملفات إلى Riverpod و GoRouter

هذا الملف يحتوي على قوالب يمكن نسخها بسهولة لتحويل الملفات المتبقية.

## 1️⃣ تحويل StatelessWidget إلى ConsumerWidget

### من:
```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ... code ...
  }
}
```

### إلى:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... code ...
  }
}
```

---

## 2️⃣ تحويل StatefulWidget إلى ConsumerStatefulWidget

### من:
```dart
class InactiveScreen extends StatefulWidget {
  const InactiveScreen({super.key});

  @override
  State<InactiveScreen> createState() => _InactiveScreenState();
}

class _InactiveScreenState extends State<InactiveScreen> {
  @override
  Widget build(BuildContext context) {
    // ... code ...
  }
}
```

### إلى:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InactiveScreen extends ConsumerStatefulWidget {
  const InactiveScreen({super.key});

  @override
  ConsumerState<InactiveScreen> createState() => _InactiveScreenState();
}

class _InactiveScreenState extends ConsumerState<InactiveScreen> {
  @override
  Widget build(BuildContext context) {
    // ... code ...
  }
}
```

---

## 3️⃣ استبدال Consumer<T> بـ ref.watch

### من:
```dart
return Consumer<AccountProvider>(
  builder: (context, account, child) {
    if (!account.isActive) {
      // ...
    }
    return Container();
  },
);
```

### إلى:
```dart
final accountState = ref.watch(accountProvider);
if (!accountState.isActive) {
  // ...
}
return Container();
```

---

## 4️⃣ استبدال Navigator بـ GoRouter

### Navigator.pushNamed
```dart
// ❌ قديم
Navigator.pushNamed(context, '/home');

// ✅ جديد
context.go('/home');
```

### Navigator.push مع arguments
```dart
// ❌ قديم
Navigator.pushNamed(
  context,
  '/editProduct',
  arguments: {'product': product},
);

// ✅ جديد
context.go('/edit-product/${product.id}');
```

### Navigator.pushReplacementNamed
```dart
// ❌ قديم
Navigator.pushReplacementNamed(context, '/home');

// ✅ جديد
context.go('/home');
```

### Navigator.pushAndRemoveUntil
```dart
// ❌ قديم
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const HomeScreen()),
  (route) => false,
);

// ✅ جديد
context.go('/home'); // سيقوم GoRouter بالتعامل مع الـ stack تلقائياً
```

### Navigator.pop
```dart
// ❌ قديم
Navigator.pop(context);

// ✅ جديد
context.pop();
```

---

## 5️⃣ استبدال Provider.of

### قراءة البيانات
```dart
// ❌ قديم
final account = Provider.of<AccountProvider>(context, listen: false);
await account.setActive(false);

// ✅ جديد
await ref.read(accountProvider.notifier).setActive(false);
```

### في initState
```dart
// ❌ قديم
@override
void initState() {
  super.initState();
  final account = Provider.of<AccountProvider>(context, listen: false);
  account.loadFromStorage();
}

// ✅ جديد
@override
void initState() {
  super.initState();
  // في ConsumerStatefulWidget، يمكن استخدام ref مباشرة
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(accountProvider.notifier).loadFromStorage();
  });
}
```

---

## 6️⃣ مثال كامل: تحويل InactiveScreen

### قبل:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class InactiveScreen extends StatelessWidget {
  const InactiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, account, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('حسابك معطل')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('الحالة: ${account.isActive ? "نشط" : "معطل"}'),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('رجوع'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### بعد:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/account_provider.dart';

class InactiveScreen extends ConsumerWidget {
  const InactiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('حسابك معطل')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('الحالة: ${accountState.isActive ? "نشط" : "معطل"}'),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 7️⃣ ملفات تحتاج تحويل فوري

ملفات Auth:
```
lib/screens/myAccount/login_screen.dart
lib/screens/myAccount/signup_step1.dart
lib/screens/myAccount/signup_step2.dart
lib/screens/myAccount/signup_step3.dart
lib/screens/myAccount/signup_step4.dart
lib/screens/myAccount/inactive_screen.dart
lib/screens/myAccount/accepted_screen.dart
lib/screens/myAccount/update_account_screen.dart
```

ملفات Details:
```
lib/screens/product_detail_screen.dart
lib/screens/edit_product_screen.dart
lib/screens/offer_detail_screen.dart
lib/screens/edit_slider_screen.dart
```

ملفات Options:
```
lib/screens/options/add_product_screen.dart
lib/screens/options/add_offer_screen.dart
lib/screens/options/add_discount_screen.dart
lib/screens/options/add_section_screen.dart
lib/screens/options/price_adjustment_screen.dart
lib/screens/options/customer_withdrawals_screen.dart
lib/screens/options/customer_withdrawals_details_screen.dart
lib/screens/options/complaints_screen.dart
lib/screens/options/suggestions_screen.dart
lib/screens/options/about_screen.dart
lib/screens/options/job_vacancies_screen.dart
lib/screens/options/add_job_vacancy_screen.dart
lib/screens/options/edit_job_vacancy_screen.dart
lib/screens/options/add_slider_screen.dart
```

---

## 🔍 Checklist للتحويل

للملف الواحد:

- [ ] إضافة `import 'package:flutter_riverpod/flutter_riverpod.dart';`
- [ ] إضافة `import 'package:go_router/go_router.dart';`
- [ ] تحويل Widget إلى ConsumerWidget/ConsumerStatefulWidget
- [ ] تحديث method signature (إضافة WidgetRef)
- [ ] استبدال كل `Navigator.*` بـ `context.*`
- [ ] استبدال كل `Consumer<T>` بـ `ref.watch(provider)`
- [ ] استبدال كل `Provider.of<T>` بـ `ref.read(provider.notifier)`
- [ ] اختبار الملف

---

**نصيحة:** استخدم Find & Replace في VS Code لتسريع العملية!

- Find: `Navigator.pushNamed\(context, '([^']+)'\)`
- Replace: `context.go('$1')`
