import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:async';
import '../services/api_service.dart';
import 'snackBar/snackbar.dart';
import '../providers/router_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasShownNoInternetMessage = false;
  bool _isCheckingLogin = false;
  bool _hasNavigated = false;
  bool _minimumSplashElapsed = false;
  bool _retryScheduled = false;
  int _currentStage = 0;
  int _dotPhase = 0;
  String? _pendingRoute;
  Timer? _dotsTimer;
  static const Duration _minimumSplashDuration = Duration(seconds: 4);
  static const List<String> _stages = <String>[
    'تهيئة التطبيق',
    'فحص التحديثات',
    'التحقق من الحساب',
    'تحديد حالة المتجر',
    'الانتقال للواجهة',
  ];
  static const String currentAppVersion = "1.0.2";
  static const String appKey = "shop";
  String _updateUrl = 'https://altallmarketshop.carrd.co';

  @override
  void initState() {
    super.initState();
    _startDotsAnimation();
    _setStage(0);

    Future.delayed(_minimumSplashDuration, () {
      if (!mounted) return;
      _minimumSplashElapsed = true;
      _tryNavigate();
    });

    // ✅ ابدأ كل التحققات أثناء عرض الصورة
    _checkLoginStatus();
  }

  void _startDotsAnimation() {
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 320), (_) {
      if (!mounted) return;
      setState(() {
        _dotPhase = (_dotPhase + 1) % 3;
      });
    });
  }

  void _setStage(int index) {
    if (!mounted) return;
    if (_currentStage == index) return;
    setState(() {
      _currentStage = index;
    });
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
    _setStage(1);

    final mustUpdate = await _shouldForceUpdate();
    if (mustUpdate) {
      _pendingRoute =
          '${AppRoutes.update}?url=${Uri.encodeComponent(_updateUrl)}';
      _isCheckingLogin = false;
      _setStage(4);
      _tryNavigate();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    _setStage(2);

    if (!mounted) {
      _isCheckingLogin = false;
      return;
    }

    if (phone == null || phone.isEmpty) {
      _pendingRoute = AppRoutes.login;
      _isCheckingLogin = false;
      _setStage(4);
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
      _setStage(2);
      _retryCheck(); // ← إعادة المحاولة كل 3 ثوانٍ
      return;
    }

    // 🛑 إذا كان الرد غير صحيح
    if (status["success"] == false) {
      _pendingRoute = AppRoutes.login;
      _isCheckingLogin = false;
      _setStage(4);
      _tryNavigate();
      return;
    }

    final data = status["data"];
    if (data is Map) {
      final prefs = await SharedPreferences.getInstance();
      final areaId = _readAreaId(data);
      if (areaId != null && areaId > 0) {
        await prefs.setInt('areaID', areaId);
      }
    }
    _setStage(3);

    if (data['shopId'] == null) {
      _pendingRoute = AppRoutes.signupStep2;
      _isCheckingLogin = false;
      _setStage(4);
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
    _setStage(4);
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

  int? _readAreaId(dynamic source) {
    if (source is! Map) return null;
    final raw = source['areaId'] ??
        source['areaID'] ??
        source['AreaID'] ??
        source['AreaId'];
    if (raw == null) return null;
    return raw is int ? raw : int.tryParse(raw.toString());
  }

  @override
  void dispose() {
    _dotsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageText = _stages[_currentStage.clamp(0, _stages.length - 1)];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, 0.55),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final active = index == _dotPhase;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: active ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1E88E5)
                                  : const Color(0xFFD7E3F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Text(
                          stageText,
                          key: ValueKey<int>(_currentStage),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF4D5B6A),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Tajawal',
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