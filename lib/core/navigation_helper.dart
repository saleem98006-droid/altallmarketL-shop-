import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';
import '../screens/myAccount/inactive_screen.dart';
import '../screens/admin_notices.dart';
import 'dart:convert';
import '../providers/router_provider.dart';


Future<void> navigateByNotification({
  required BuildContext context,
  required String? screen,
  Map<String, dynamic>? data,     // 🔵 كما في الدالة القديمة
  int? relatedId,                 // 🔵 كما في الدالة الجديدة
}) async {
  debugPrint("🔔 NavigateByNotification => screen: $screen, data: $data, relatedId: $relatedId");

  switch (screen) {

    // ---------------------------------------------------------
    // 🔵 1) فتح تبويب داخل HomeScreen
    // ---------------------------------------------------------
    case "NewOrder":
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(initialTabIndex: 2),
        ),
        (route) => false,
      );
      break;

    case "OrdersTab":
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(initialTabIndex: 1),
        ),
        (route) => false,
      );
      break;

    case "HomeTab":
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(initialTabIndex: 0),
        ),
        (route) => false,
      );
      break;

      case "manager":
  if (data != null) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => AdminNoticesScreen(
          title: data["title"] ?? "إشعار إداري",
          body: data["body"] ?? "لا يوجد تفاصيل",
        ),
      ),
      (route) => false,  
    );
  }
  break;

    // ---------------------------------------------------------
    // 🔵 2) حالات الحساب (قبول – إيقاف – إعادة تفعيل)
    // ---------------------------------------------------------
    case "Approved":
      {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isAccepted", true);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(initialTabIndex: 0),
          ),
          (route) => false,
        );
      }
      break;

    case "Deactivated":
      {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isActive", false);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const InactiveScreen()),
          (route) => false,
        );
      }
      break;

    case "Reactivated":
      {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isActive", true);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(initialTabIndex: 0),
          ),
          (route) => false,
        );
      }
      break;

    // ---------------------------------------------------------
    // 🔵 3) التنقّل عبر Routes + تمرير data (كما في الدالة القديمة)
    // ---------------------------------------------------------
    case "product":
      if (data != null && data["product"] != null) {
        context.push(
          AppRoutes.productDetail,
          extra: {
            'product': data["product"],
            'offer': data["offer"],
          },
        );
      }
      break;

    case "offer":
      if (data != null && data["offer"] != null) {
        context.push(
          AppRoutes.offerDetail,
          extra: {
            'offer': data["offer"],
            'product': data["product"],
          },
        );
      }
      break;

    case "withdraw":
      context.push(AppRoutes.customerWithdrawals);
      break;

    case "complaint":
      context.push(AppRoutes.complaints);
      break;

    case "suggestion":
      context.push(AppRoutes.suggestions);
      break;

    case "MonthlyPayment":
    case "monthlypayment":
    case "MonthlyPaymentt":
    case "monthlypaymentt":
      context.push(AppRoutes.monthlyDues);
      break;

    // ---------------------------------------------------------
    // 🔵 4) شاشات تعتمد على relatedId (تفاصيل طلب – تفاصيل منتج – إلخ)
    // ---------------------------------------------------------
    case "OrderDetailsScreen":
      if (relatedId != null) {
        Navigator.pushNamed(
          context,
          "/orderDetails",
          arguments: {"orderId": relatedId},
        );
      }
      break;

    case "ProductScreen":
      if (relatedId != null) {
        Navigator.pushNamed(
          context,
          "/product",
          arguments: {"id": relatedId},
        );
      }
      break;

  // ---------------------------------------------------------
    // 🔵 4) شاشة التحديث الإجباري
    // ---------------------------------------------------------
    case "Update":
    case "ForceUpdate":
    case "AppUpdate":
      {
        final String storeUrl = data?["storeUrl"] as String? ??
            data?["url"] as String? ??
            'https://altallmarketdelivery.carrd.co';
        final encoded = Uri.encodeComponent(storeUrl);
        context.go('${AppRoutes.update}?url=$encoded');
      }
      break;


    // ---------------------------------------------------------
    // 🔵 5) شاشة غير معروفة → افتح الرئيسية
    // ---------------------------------------------------------
    
/*default:
  debugPrint("⚠️ شاشة غير معروفة: $screen — فتح صفحة الإشعار الإداري");

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AdminNoticesScreen(
        title: data?["title"] ?? "إشعار من الإدارة",
        body: data?["body"] ?? "تم استلام إشعار بدون تفاصيل.",
      ),
    ),
  );
  break;*/

  default:
  debugPrint("⚠️ شاشة غير معروفة: $screen — فتح صفحة الإشعار الإداري");

  dynamic extraRaw = data?["extra"];
  Map<String, dynamic> extra = {};

  // 🔵 إذا كانت extra Map<dynamic, dynamic> → نحولها إلى Map<String, dynamic>
  if (extraRaw is Map) {
    extra = extraRaw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  // 🔵 إذا كانت extra String → JSON decode
  else if (extraRaw is String) {
    try {
      final decoded = jsonDecode(extraRaw);
      if (decoded is Map) {
        extra = decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (e) {
      debugPrint("⚠️ فشل تحويل extra من String إلى Map: $e");
    }
  }

  final String title =
      extra["title"] ??
      data?["title"] ??
      "إشعار من الإدارة";

  final String body =
      extra["message"] ??
      data?["body"] ??
      "لديك اشعارات جديدة يرجى الانتباه";

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AdminNoticesScreen(
        title: title,
        body: body,
      ),
    ),
  );
  break;
  }
}