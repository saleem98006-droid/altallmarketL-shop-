import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/account_provider.dart';
import '../../providers/router_provider.dart';
import '../home_screen.dart';
import '../myAccount/inactive_screen.dart';

class SignupStep4 extends ConsumerStatefulWidget {
  const SignupStep4({super.key});

  @override
  ConsumerState<SignupStep4> createState() => _SignupStep4State();
}

class _SignupStep4State extends ConsumerState<SignupStep4>
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

  Future<void> _openWhatsApp(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString("fullName") ?? "المستخدم";

    final phone = "963956901603";
    final message = Uri.encodeComponent(
        "السلام عليكم، أنا $fullName وأود إعلامكم بإنني أنهيت التسجيل وأنتظر موافقتكم الكريمة على طلبي.");
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
    
    // 🟢 إذا تم قبول الحساب → انتقل للهوم مباشرة
    if (accountState.isAccepted) {
      Future.microtask(() {
        context.go(AppRoutes.home);
      });
    }

    // 🔴 إذا تم تعطيل الحساب → انتقل لصفحة التعطيل
    if (!accountState.isActive) {
      Future.microtask(() {
        context.go(AppRoutes.inactive);
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
                          const Text(
                            "تم استلام طلبك\nفي انتظار الموافقة عليه من طرف الإدارة",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: Colors.black,
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
                                  color: Colors.blue,
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