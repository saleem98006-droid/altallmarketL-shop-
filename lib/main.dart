import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notification_handlers.dart';
import 'dart:convert';
import 'providers/router_provider.dart';
import 'providers/account_provider.dart';
import 'theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'services/dio_service.dart';
import 'core/notification_helper_router.dart';

// 👇 مفاتيح الإشعارات والإشعارات
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final StreamController<Map<String, dynamic>> notificationTapStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
  'default_channel',
  'Default Channel',
  description: 'القناة الافتراضية لعرض الإشعارات',
  importance: Importance.max,
);

// 👇 دالة الخلفية للإشعارات
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.notification == null) {
    final title = message.data['title'] ?? 'تنبيه';
    final body = message.data['body'] ?? 'لديك رسالة جديدة';

    flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'القناة الافتراضية لعرض الإشعارات',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
    );
  }
}

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp();
      DioService.initialize();

      // طلب صلاحيات FCM
      await FirebaseMessaging.instance.requestPermission();

      // صلاحيات أندرويد 13+
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // تهيئة الإشعارات المحلية
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            final data = jsonDecode(response.payload!);
            notificationTapStreamController.add(
              Map<String, dynamic>.from(data as Map),
            );
          }
        },
      );

      // إنشاء القناة
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(defaultChannel);

      // تسجيل دالة الخلفية
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      runApp(
        const ProviderScope(
          child: MyApp(),
        ),
      );
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Unhandled zone error: $error');
        debugPrint('$stack');
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (kDebugMode) {
          parent.print(zone, line);
        }
      },
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<Map<String, dynamic>>? _notificationTapSubscription;

  Future<void> _syncAccountProviderFromNotification(
    Map<String, dynamic> data,
  ) async {
    final screen = (data['screen'] ?? '').toString();
    final accountNotifier = ref.read(accountProvider.notifier);

    if (screen == 'Deactivated') {
      await accountNotifier.setActive(false);
      return;
    }

    if (screen == 'Reactivated') {
      await accountNotifier.setActive(true);
      return;
    }

    if (screen == 'Approved') {
      await accountNotifier.setAccepted(true);
    }
  }

  int? _extractRelatedId(Map<String, dynamic> data) {
    final keys = ['relatedId', 'shopOrderId', 'shopOrderID', 'sourceId', 'id'];
    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<void> _handleNotificationNavigation(Map<String, dynamic> data) async {
    final router = ref.read(goRouterProvider);
    final screen = (data['screen'] ?? '').toString();

    await navigateByNotificationRouter(
      router: router,
      screen: screen,
      data: data,
      relatedId: _extractRelatedId(data),
    );
  }

  @override
  void initState() {
    super.initState();

    _notificationTapSubscription = notificationTapStreamController.stream.listen(
      (data) async {
        await _syncAccountProviderFromNotification(data);
        await _handleNotificationNavigation(data);
      },
    );

    // استقبال أثناء فتح التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await handleNotificationArrival(message);
      await _syncAccountProviderFromNotification(message.data);

      final title = message.data['title'] ?? 'تنبيه';
      final body = message.data['body'] ?? 'لديك رسالة جديدة';

      flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Channel',
            channelDescription: 'القناة الافتراضية لعرض الإشعارات',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // فتح التطبيق من إشعار بالخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint("🔥 OPENED APP NOTIFICATION DATA => ${message.data}");
      await handleNotificationArrival(message);
      await _syncAccountProviderFromNotification(message.data);
      await _handleNotificationNavigation(message.data);
    });

    // فتح التطبيق من إشعار وهو مغلق
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      if (message != null) {
        await handleNotificationArrival(message);
        await _syncAccountProviderFromNotification(message.data);
        await _handleNotificationNavigation(message.data);
      }
    });
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      title: 'Shop Owner App',
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: child!,
        );
      },
    );
  }
}