import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'about_screen.dart';
import 'complaints_screen.dart';
import 'suggestions_screen.dart';
import '../../providers/account_provider.dart';
import '../../providers/router_provider.dart';
import '../../widgets/loading_dots_widget.dart';

class OptionsTab extends ConsumerStatefulWidget {
  const OptionsTab({super.key});

  @override
  ConsumerState<OptionsTab> createState() => _OptionsTabState();
}

class _OptionsTabState extends ConsumerState<OptionsTab> {
  bool confirming = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.only(right: 0),
        children: [
          // ✅ قائمة المنتجات والعروض
          ListTile(
            trailing: Image.asset("assets/images/Add1.png", width: 28, height: 28),
            title: const Text("إضافة منتج", textAlign: TextAlign.right, style: TextStyle(fontSize: 22)),
            onTap: () => context.go(AppRoutes.addProduct),
          ),
          ListTile(
            trailing: Image.asset("assets/images/Add2.png", width: 28, height: 28),
            title: const Text("إضافة وإدارة التصنيفات", textAlign: TextAlign.right, style: TextStyle(fontSize: 22)),
            onTap: () => context.go(AppRoutes.addSection),
          ),
          ListTile(
            trailing: Image.asset("assets/images/Add1.png", width: 28, height: 28),
            title: const Text(
              "إضافة عرض أو خصم",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 22),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                backgroundColor: Colors.white,
                builder: (context) {
                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Image.asset("assets/images/Add1.png", width: 26, height: 26),
                          title: const Text(
                            "إضافة عرض",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context.go(AppRoutes.addOffer);
                          },
                        ),
                        ListTile(
                          leading: Image.asset("assets/images/Add2.png", width: 26, height: 26),
                          title: const Text(
                            "إضافة خصم",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context.go(AppRoutes.addDiscount);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          ListTile(
            trailing: Image.asset("assets/images/Add2.png", width: 28, height: 28),
            title: const Text("إضافة سلايدر", textAlign: TextAlign.right, style: TextStyle(fontSize: 22)),
            onTap: () => context.go(AppRoutes.addSlider),
          ),
          ListTile(
            trailing: Image.asset("assets/images/update1.png", width: 28, height: 28),
            title: const Text("تعديل الأسعار", textAlign: TextAlign.right, style: TextStyle(fontSize: 22)),
            onTap: () => context.go(AppRoutes.priceAdjustment),
          ),
          ListTile(
            trailing: Image.asset("assets/images/customer.png", width: 28, height: 28),
            title: const Text("مسحوبات الزبائن", textAlign: TextAlign.right, style: TextStyle(fontSize: 22)),
            onTap: () => context.go(AppRoutes.customerWithdrawals),
          ),
          ListTile(
            trailing: Image.asset("assets/images/update1.png", width: 28, height: 28),
            title: const Text(
              "إدارة شواغر العمل",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 22),
            ),
            onTap: () => context.go(AppRoutes.jobVacancies),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.06),
          ListTile(
            trailing: Image.asset("assets/images/complaints.png", width: 28, height: 28),
            title: const Text("شكاوي", textAlign: TextAlign.right, style: TextStyle(fontSize: 22)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ComplaintsScreen())),
          ),
          ListTile(
            trailing: Image.asset("assets/images/Suggestions.png", width: 28, height: 28),
            title: const Text("اقتراحات", textAlign: TextAlign.right, style: TextStyle(fontSize: 22)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionsScreen())),
          ),
          ListTile(
            trailing: Image.asset("assets/images/about.png", width: 28, height: 28),
            title: const Text("حول", textAlign: TextAlign.right, style: TextStyle(fontSize: 22)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())),
          ),
          ListTile(
            trailing: Image.asset("assets/images/SignOut.png", width: 28, height: 28),
            title: const Text(
              "تسجيل خروج",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 22),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        content: const Text(
                          "هل أنت متأكد",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Tajawal",
                            color: Colors.black,
                          ),
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 45,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(
                                        color: Color(0xFFFF0000),
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: confirming
                                        ? null
                                        : () async {
                                            setState(() => confirming = true);
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.clear();
                                            ref.read(accountProvider.notifier).reset();
                                            await Future.delayed(const Duration(milliseconds: 500));
                                            if (!mounted) return;
                                            context.go(AppRoutes.login);
                                          },
                                    child: confirming
                                        ? const LoadingDotsWidget(color: Colors.red)
                                        : const Text(
                                            "تأكيد",
                                            style: TextStyle(
                                              fontFamily: "Tajawal",
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 45,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(
                                        color: Color(0xFF5A9BD5),
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: confirming ? null : () => Navigator.pop(context),
                                    child: const Text(
                                      "إلغاء",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: "Tajawal",
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 75),
        ],
      ),
    );
  }
}
