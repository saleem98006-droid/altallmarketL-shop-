import 'dart:ui'; // 👈 مهم للغباش
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart'; // تأكدي من وجود هذا الملف
import '../snackBar/snackbar.dart';
import '../../widgets/loading_dots_widget.dart';
import '../../providers/router_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

Future<void> _login() async {
  // امسح الأخطاء السابقة
  setState(() {
    _phoneError = null;
    _passwordError = null;
  });

  final phone = phoneController.text.trim();
  final password = passwordController.text.trim();

  // ✅ تحقق مطلوب لكل حقل
  bool hasError = false;
  if (phone.isEmpty) {
    _phoneError = "مطلوب";
    hasError = true;
  }
  if (password.isEmpty) {
    _passwordError = "مطلوب";
    hasError = true;
  }
  if (hasError) {
    setState(() {}); // لتحديث الـ UI وعرض الأخطاء تحت الحقول
    return;          // ⬅️ لا تكمل للتنقل
  }

  setState(() => _isLoading = true);
  final response = await ApiService.loginOwner(phone, password);
  setState(() => _isLoading = false);

  // ✅ فشل الاتصال/الرد
  if (response == null) {
    setState(() {
      _phoneError = "فشل تسجيل الدخول، تحقق من البيانات";
    });
    return; // ⬅️ لا تنقل
  }

  // ✅ اقرأ الخطأ من المفتاح "error" إذا كان موجود
  final error = response['error']?.toString() ?? "";

  if (error.isNotEmpty) {
    if (error.contains("رقم الهاتف")) {
      setState(() {
        _phoneError = "رقم الهاتف غير صحيح";
        _passwordError = null;
      });
      phoneFocus.requestFocus();
    } else if (error.contains("كلمة المرور")) {
      setState(() {
        _passwordError = "كلمة المرور غير صحيحة";
        _phoneError = null;
      });
      passwordFocus.requestFocus();
    } else {
      setState(() {
        _phoneError = error; // خطأ عام
      });
    }
    return; // ⬅️ مهم: لا تكمل إلى التنقل
  }

  // ✅ نجاح: حفظ البيانات والتنقل
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
  await prefs.setBool('isApproved', response['isApproved'] == true);
  await prefs.setBool('isActive', response['isActive'] == true);
  await prefs.setString('phoneNumber', phone);

  final ownerId = int.tryParse(response['shopOwnerId'].toString()) ?? 0;
  await prefs.setInt('ownerId', ownerId);

  if (response['shopId'] != null) {
    final shopId = int.tryParse(response['shopId'].toString()) ?? 0;
    await prefs.setInt('shopId', shopId);
  }

  // ✅ الحصول على التوكين من Firebase
  String? fcmToken = await FirebaseMessaging.instance.getToken();

  if (fcmToken != null && ownerId != 0) {
    // ✅ حفظ التوكين في قاعدة البيانات
    await ApiService.saveUserToken(
      userType: "Shop",      // ← بدل Delivery إلى Shop
      userId: ownerId,       // ← استخدم shopOwnerId
      fcmToken: fcmToken,
    );

    // ✅ حفظ التوكين محليًا أيضًا
    await prefs.setString('fcmToken', fcmToken);
  }

  if (!mounted) return;
  final hasShop = response['shopId'] != null && response['shopId'].toString().isNotEmpty;
  final isApproved = response['isApproved'] == true;
  final isActive = response['isActive'] == true;

  if (isActive && isApproved && hasShop) {
    context.go(AppRoutes.home);
  } else if (isActive && !isApproved && hasShop) {
    context.go(AppRoutes.signupStep4);
  } else if (isActive && !isApproved && !hasShop) {
    context.go(AppRoutes.signupStep2);
  } else if (!isActive && isApproved && hasShop) {
    context.go(AppRoutes.inactive);
  } else {
    context.go(AppRoutes.inactive);
  }
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الخلفية
            Image.asset(
              'assets/images/altalLogo.png',
              fit: BoxFit.cover,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.white.withOpacity(0.6)),
            ),

            // المحتوى
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'أهلا بك',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'الكثير بانتظارك',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ✅ الحقول تأخذ الثيم الأساسي مباشرة
                  TextField(
                    controller: phoneController,
                    focusNode: phoneFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      errorText: _phoneError,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    focusNode: passwordFocus,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: (passwordFocus.hasFocus || passwordController.text.isNotEmpty)
                              ? const Color(0xFF5A9BD5)
                              : Colors.black87,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ✅ الزر يأخذ الثيم الأساسي
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const LoadingDotsWidget()
                          : const Text('تسجيل الدخول'),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            /// ✅ الجزء المثبت في الأسفل
            Positioned(
              bottom: screenHeight * 0.1,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ليس لديك حساب؟',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      context.push(AppRoutes.signupStep1);
                    },
                    child: const Text(
                      'سجل الآن',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5A9BD5),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}