import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'snackBar/snackbar.dart';
import '../providers/router_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _hasShownNoInternetMessage = false;
  bool _isCheckingLogin = false;
  bool _hasNavigated = false;
  bool _minimumSplashElapsed = false;
  bool _retryScheduled = false;
  String? _pendingRoute;
  static const String currentAppVersion = "1.0.1";
  static const String appKey = "shop";
  String _updateUrl = 'https://altallmarketshop.carrd.co';

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
        _controller.setLooping(false);
      }).catchError((_) {
        // تجاهل خطأ الفيديو حتى لا يعطل الدخول
      });

    // ⏱️ مدة شاشة البداية ثابتة 5 ثوانٍ
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _minimumSplashElapsed = true;
      if (_controller.value.isInitialized) {
        _controller.pause();
      }
      _tryNavigate();
    });

    // ✅ ابدأ كل التحققات أثناء تشغيل الفيديو
    _checkLoginStatus();
  }

  void _retryCheck() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    Future.delayed(const Duration(seconds: 3), () {
      _retryScheduled = false;
      if (mounted) {
        _checkLoginStatus();
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    if (_isCheckingLogin || _hasNavigated) return;
    _isCheckingLogin = true;

    final mustUpdate = await _shouldForceUpdate();
    if (mustUpdate) {
      _pendingRoute =
          '${AppRoutes.update}?url=${Uri.encodeComponent(_updateUrl)}';
      _isCheckingLogin = false;
      _tryNavigate();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');

    if (!mounted) {
      _isCheckingLogin = false;
      return;
    }

    if (phone == null || phone.isEmpty) {
      _pendingRoute = AppRoutes.login;
      _isCheckingLogin = false;
      _tryNavigate();
      return;
    }

    final status = await ApiService.checkOwnerStatus(phone);

    // 🛑 إذا كان هناك مشكلة شبكة → لا ننتقل لأي صفحة
    if (status["success"] == false && status["error"] == "network_error") {
      // ⭐ إظهار الرسالة مرة واحدة فقط
      if (!_hasShownNoInternetMessage) {
        _hasShownNoInternetMessage = true;
        snackBar(context, "لا يوجد اتصال بالإنترنت");
      }
      _isCheckingLogin = false;
      _retryCheck(); // ← إعادة المحاولة كل 3 ثوانٍ
      return;
    }

    // 🛑 إذا كان الرد غير صحيح
    if (status["success"] == false) {
      _pendingRoute = AppRoutes.login;
      _isCheckingLogin = false;
      _tryNavigate();
      return;
    }

    final data = status["data"];

    if (data['shopId'] == null) {
      _pendingRoute = AppRoutes.signupStep2;
      _isCheckingLogin = false;
      _tryNavigate();
      return;
    }

    final isApproved = data['isApproved'] == true;
    final isActive = data['isActive'] == true;

    if (isApproved) {
      if (isActive) {
        _pendingRoute = AppRoutes.home;
      } else {
        _pendingRoute = AppRoutes.inactive;
      }
    } else {
      _pendingRoute = AppRoutes.signupStep4;
    }

    _isCheckingLogin = false;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!mounted) return;
    if (_hasNavigated) return;
    if (!_minimumSplashElapsed) return;
    if (_pendingRoute == null) return;

    _hasNavigated = true;
    context.go(_pendingRoute!);
  }

  Future<bool> _shouldForceUpdate() async {
    try {
      final platform = Platform.isIOS ? "ios" : "android";
      final updateInfo = await ApiService.checkAppUpdate(
        platform,
        appKey: appKey,
      );

      if (updateInfo != null && updateInfo["success"] == true) {
        final latest =
            updateInfo["latestVersion"]?.toString() ?? currentAppVersion;
        final force = _toBool(updateInfo["forceUpdate"]);

        final backendUrl = _extractStoreUrl(updateInfo, platform);
        if (backendUrl != null && backendUrl.isNotEmpty) {
          _updateUrl = backendUrl;
        }

        return force && _isVersionOlder(currentAppVersion, latest);
      }
    } catch (_) {
      // تجاهل الخطأ حتى لا يتوقف مسار الدخول
    }

    return false;
  }

  String? _extractStoreUrl(Map<String, dynamic> updateInfo, String platform) {
    final normalizedPlatform = platform.toLowerCase();

    String? readString(dynamic value) {
      if (value is String) {
        final v = value.trim();
        if (v.isNotEmpty) return v;
      }
      return null;
    }

    // مفاتيح شائعة خاصة بالمنصة
    if (normalizedPlatform == 'android') {
      final v = readString(updateInfo['androidUrl']) ??
          readString(updateInfo['playStoreUrl']) ??
          readString(updateInfo['androidStoreUrl']);
      if (v != null) return v;
    } else {
      final v = readString(updateInfo['iosUrl']) ??
          readString(updateInfo['appStoreUrl']) ??
          readString(updateInfo['iosStoreUrl']);
      if (v != null) return v;
    }

    // مفاتيح عامة
    return readString(updateInfo['storeUrl']) ??
        readString(updateInfo['url']) ??
        readString(updateInfo['link']) ??
        readString(updateInfo['updateUrl']);
  }

  bool _isVersionOlder(String current, String latest) {
    final c = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList(growable: false);
    final l = latest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList(growable: false);

    final maxLen = c.length > l.length ? c.length : l.length;
    for (int i = 0; i < maxLen; i++) {
      final cv = i < c.length ? c[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (cv < lv) return true;
      if (cv > lv) return false;
    }
    return false;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Container(color: Colors.black),
    );
  }
}