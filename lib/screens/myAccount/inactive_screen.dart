import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/account_provider.dart';
import '../../providers/router_provider.dart';
import '../home_screen.dart';
import 'signup_step4.dart'; // صفحة القبول

class InactiveScreen extends ConsumerStatefulWidget {
  const InactiveScreen({super.key});

  @override
  ConsumerState<InactiveScreen> createState() => _InactiveScreenState();
}

class _InactiveScreenState extends ConsumerState<InactiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulse = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ref.read(accountProvider.notifier).reset();
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString("fullName") ?? "المستخدم";

    final phone = "963956901603";
    final message =
        Uri.encodeComponent("السلام عليكم، أنا $fullName لماذا حسابي معطل؟");
    final link = "https://wa.me/$phone?text=$message";

    final ok = await launchUrlString(
      link,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ تعذر فتح واتساب عبر الرابط الخارجي")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    
    // 🟢 إذا تم إعادة التفعيل → انتقل للهوم
    if (accountState.isActive) {
      Future.microtask(() {
        context.go(AppRoutes.home);
      });
    }

    // 🟡 إذا تم قبول الحساب بعد التعطيل → انتقل لصفحة القبول
    if (accountState.isAccepted && !accountState.isActive) {
      Future.microtask(() {
        context.go(AppRoutes.signup4);
      });
    }

        return WillPopScope(
          onWillPop: () async {
            SystemNavigator.pop();
            return false;
          },
          child: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/altalLogo.png',
                    fit: BoxFit.cover,
                  ),

                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.block,
                              size: 100, color: Colors.redAccent),
                          const SizedBox(height: 20),
                          const Text(
                            "حسابك غير نشط حالياً",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "يرجى التواصل مع الإدارة لتفعيل حسابك.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Tajawal',
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 40),

                          Column(
                            children: const [
                              Text(
                                "Altall Market",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                  fontFamily: 'VladiirScript',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Your comfort is our priority",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black45,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 60),

                          GestureDetector(
                            onTap: () => _openWhatsApp(context),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 1.0, end: 1.1)
                                  .animate(_pulse),
                              child: const Text(
                                "للاستفسار",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF5A9BD5),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "تواصل معنا",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontFamily: 'Tajawal',
                            ),
                          ),

                          const SizedBox(height: 40),

                          ElevatedButton.icon(
                            onPressed: () => _logout(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35),
                              ),
                              side: const BorderSide(
                                  color: Color(0xFF5A9BD5), width: 3),
                              elevation: 0,
                            ),
                            label: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Tajawal',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}