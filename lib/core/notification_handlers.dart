import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final ValueNotifier<int> newOrderNotificationTick = ValueNotifier<int>(0);
final ValueNotifier<int> notificationsTick = ValueNotifier<int>(0);

@pragma('vm:entry-point')
Future<void> handleNotificationArrival(RemoteMessage message) async {
  final screen = message.data["screen"];
  final prefs = await SharedPreferences.getInstance();

  notificationsTick.value++;

  final normalized = (screen ?? '').toString().trim().toLowerCase();
  if (normalized == 'neworder' ||
      normalized == 'new_order' ||
      normalized == 'ordersnewtab') {
    await prefs.setBool('hasPendingNewOrders', true);
    newOrderNotificationTick.value++;
  }

  if (screen == "Deactivated") {
    await prefs.setBool("isActive", false);
  }

  if (screen == "Reactivated") {
    await prefs.setBool("isActive", true);
  }

  if (screen == "Approved") {
    await prefs.setBool("isAccepted", true);
  }
}

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await handleNotificationArrival(message);
}