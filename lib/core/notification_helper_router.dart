import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/router_provider.dart';

/// Handle notification navigation with GoRouter
Future<void> navigateByNotificationRouter({
  required GoRouter router,
  required String? screen,
  Map<String, dynamic>? data,
  int? relatedId,
}) async {
  debugPrint("🔔 NavigateByNotificationRouter => screen: $screen, data: $data, relatedId: $relatedId");

  final normalized = (screen ?? '').trim().toLowerCase();
  if (normalized == 'neworder' || normalized == 'new_order' || normalized == 'ordersnewtab') {
    router.go('${AppRoutes.home}?tab=2');
    return;
  }
  if (normalized == 'orderstab' || normalized == 'orders_tab') {
    router.go('${AppRoutes.home}?tab=1');
    return;
  }
  if (normalized == 'hometab' || normalized == 'home_tab') {
    router.go('${AppRoutes.home}?tab=0');
    return;
  }

  switch (screen) {
    // --------- Tabs inside HomeScreen ---------
    case "NewOrder":
      router.go('${AppRoutes.home}?tab=2');
      break;

    case "OrdersTab":
      router.go('${AppRoutes.home}?tab=1');
      break;

    case "HomeTab":
      router.go('${AppRoutes.home}?tab=0');
      break;

    // --------- Account Status Changes ---------
    case "Approved":
      {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isAccepted", true);
        router.go(AppRoutes.home);
      }
      break;

    case "Deactivated":
      {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isActive", false);
        router.go(AppRoutes.inactive);
      }
      break;

    case "Reactivated":
      {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isActive", true);
        router.go(AppRoutes.home);
      }
      break;

    // --------- Navigation with parameters ---------
    case "product":
      if (data != null && data["product"] != null) {
        final productId = data["product"]["productId"]?.toString() ?? "";
        if (productId.isNotEmpty) {
          router.go('${AppRoutes.productDetail.replaceAll(':id', productId)}');
        }
      }
      break;

    case "offer":
      if (data != null && data["offer"] != null) {
        final offerId = data["offer"]["offerId"]?.toString() ?? "";
        if (offerId.isNotEmpty) {
          router.go('${AppRoutes.offerDetail.replaceAll(':id', offerId)}');
        }
      }
      break;

    case "withdraw":
      router.go(AppRoutes.customerWithdrawals);
      break;

    case "complaint":
      router.go(AppRoutes.complaints);
      break;

    case "suggestion":
      router.go(AppRoutes.suggestions);
      break;

    case "MonthlyPayment":
    case "monthlypayment":
    case "MonthlyPaymentt":
    case "monthlypaymentt":
      router.go(AppRoutes.monthlyDues);
      break;

    // --------- Details Screen (relatedId) ---------
    case "OrderDetailsScreen":
      if (relatedId != null) {
        // Navigate to order details if available
        router.go('${AppRoutes.home}?tab=1&orderId=$relatedId');
      }
      break;

    case "ProductScreen":
      if (relatedId != null) {
        router.go('${AppRoutes.productDetail.replaceAll(':id', relatedId.toString())}');
      }
      break;

    // --------- App Update ---------
    case "Update":
    case "ForceUpdate":
    case "AppUpdate":
      {
        final String storeUrl = data?["storeUrl"] as String? ??
            data?["url"] as String? ??
            'https://altallmarketdelivery.carrd.co';
        router.go('${AppRoutes.update}?url=$storeUrl');
      }
      break;

    // --------- Admin Notice (default) ---------
    default:
      debugPrint("⚠️ Unknown screen: $screen — showing admin notice");
      // Could implement an admin notice route or dialog
      break;
  }
}
