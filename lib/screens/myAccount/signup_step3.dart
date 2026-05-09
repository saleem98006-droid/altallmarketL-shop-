import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import '../../services/api_service.dart';
import '../../providers/router_provider.dart';
import '../snackBar/snackbar.dart';
import '../../utils/image_compressor.dart';
import '../../widgets/loading_dots_widget.dart';

class SignupStep3 extends StatefulWidget {
  const SignupStep3({super.key});

  @override
  State<SignupStep3> createState() => _SignupStep3State();
}

class _SignupStep3State extends State<SignupStep3> {
  final List<String> days = const [
    "السبت", "الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"
  ];

  final Map<String, TextEditingController> openControllers = {};
  final Map<String, TextEditingController> closeControllers = {};
  final Map<String, bool> holiday = {};
  
  File? coverImage;
  File? logoImage;
  bool _isLoading = false;

  Future<_LocationCoords?> _resolveShopCoordinates() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) إذا الإحداثيات محفوظة من الخطوة السابقة نستخدمها مباشرة
    final savedLat = prefs.getDouble('latitude');
    final savedLng = prefs.getDouble('longitude');
    if (savedLat != null && savedLng != null) {
      return _LocationCoords(lat: savedLat, lng: savedLng);
    }

    // 2) fallback: الحصول على الموقع الحالي مثل تسجيل صاحب المحل
    final location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }
    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever) {
      return null;
    }

    await location.changeSettings(
      accuracy: LocationAccuracy.low,
      interval: 1000,
      distanceFilter: 0,
    );

    double? lat;
    double? lng;

    try {
      final current = await location
          .getLocation()
          .timeout(const Duration(seconds: 10));
      lat = current.latitude;
      lng = current.longitude;
    } catch (_) {}

    if (lat == null || lng == null) {
      try {
        await location.changeSettings(accuracy: LocationAccuracy.navigation);
        final retry = await location
            .getLocation()
            .timeout(const Duration(seconds: 8));
        lat = retry.latitude;
        lng = retry.longitude;
      } catch (_) {}
    }

    if (lat == null || lng == null) return null;

    // 3) حفظها لكي تُستخدم لاحقاً بدون إعادة طلب GPS
    await prefs.setDouble('latitude', lat);
    await prefs.setDouble('longitude', lng);

    return _LocationCoords(lat: lat, lng: lng);
  }

  Future<_AreaCheckResult> _checkCoverageForCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final areas = await ApiService.getAreas();
      if (areas == null || areas.isEmpty) {
        return const _AreaCheckResult(
          isCovered: false,
          errorMessage: 'تعذّر تحميل مناطق الخدمة حالياً.',
        );
      }

      for (final area in areas) {
        final isActive = _toBool(area['isactive'] ?? area['isActive']);
        if (!isActive) continue;

        final points = _parsePolygonPoints(area['polygon']);
        if (points.length < 3) continue;

        if (_isPointInPolygon(lat, lng, points)) {
          final detectedAreaId =
              int.tryParse((area['areaID'] ?? area['AreaID'] ?? '').toString());
          final detectedAreaName =
              (area['areaName'] ?? area['AreaName'] ?? '').toString().trim();

          if (detectedAreaId == null) {
            return const _AreaCheckResult(
              isCovered: false,
              errorMessage: 'تم العثور على منطقة مطابقة لكن رقم المنطقة غير متوفر.',
            );
          }

          return _AreaCheckResult(
            isCovered: true,
            areaID: detectedAreaId,
            areaName: detectedAreaName,
          );
        }
      }

      return const _AreaCheckResult(
        isCovered: false,
        errorMessage: 'عذراً، الخدمة غير متوفرة في منطقتك حالياً.',
      );
    } catch (_) {
      return const _AreaCheckResult(
        isCovered: false,
        errorMessage: 'حدث خطأ أثناء التحقق من منطقتك. حاول مرة أخرى.',
      );
    }
  }

  Future<void> _showServiceUnavailableDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          title: const Center(
            child: Text(
              'عذراً',
              textAlign: TextAlign.center,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.blue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'حسناً',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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

  List<_MapPoint> _parsePolygonPoints(dynamic polygonRaw) {
    dynamic normalized = polygonRaw;

    if (normalized is String) {
      final txt = normalized.trim();
      if (txt.isEmpty) return const [];
      try {
        normalized = jsonDecode(txt);
      } catch (_) {
        return const [];
      }
    }

    if (normalized is! List) return const [];

    final result = <_MapPoint>[];
    for (final p in normalized) {
      if (p is! Map) continue;

      final latRaw = p['lat'] ?? p['latitude'] ?? p['Lat'];
      final lngRaw = p['lng'] ?? p['lon'] ?? p['longitude'] ?? p['Lng'];

      final pLat = _toDouble(latRaw);
      final pLng = _toDouble(lngRaw);

      if (pLat == null || pLng == null) continue;
      result.add(_MapPoint(lat: pLat, lng: pLng));
    }

    return result;
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  bool _isPointInPolygon(double lat, double lng, List<_MapPoint> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].lng;
      final yi = polygon[i].lat;
      final xj = polygon[j].lng;
      final yj = polygon[j].lat;

      final intersects = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / ((yj - yi) + 1e-12) + xi);

      if (intersects) inside = !inside;
    }
    return inside;
  }

  @override
  void initState() {
    super.initState();
    for (final day in days) {
      openControllers[day] = TextEditingController();
      closeControllers[day] = TextEditingController();
      holiday[day] = false;
    }
  }

  @override
  void dispose() {
    for (final c in openControllers.values) {
      c.dispose();
    }
    for (final c in closeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(bool isCover) async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

  if (picked != null) {
    final file = File(picked.path);
    final bytes = await file.readAsBytes(); // للعرض

    setState(() {
      if (isCover) {
        coverImage = file;
       
        snackBar(context, "تم اختيار صورة الغلاف");
      } else {
        logoImage = file;
       
        snackBar(context, "تم اختيار صورة اللوغو");
      }
    });
  } else {
    snackBar(context, "لم يتم اختيار اي صورة");
  }
}

  

  Future<void> _pickTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
   if (picked != null) {
    // ✅ صيغة مناسبة لقاعدة البيانات (TIME)
    final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
    controller.text = formatted;
  }

  }
 Future<void> _submitShop() async {
    if (_isLoading) return;
  setState(() => _isLoading = true);

  final prefs = await SharedPreferences.getInstance();
    final existingShopId = prefs.getInt('shopId');
    if (existingShopId != null && existingShopId > 0) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.go(AppRoutes.signupStep4);
      return;
    }

  final shopName = prefs.getString('shopName') ?? '';
  final address = prefs.getString('address') ?? '';
  final detailes = prefs.getString('detailes') ?? '';
  final categoryId = prefs.getInt('categoryId') ?? 0;
  final phones = prefs.getStringList('shopPhones') ?? [];
  final ownerId = prefs.getInt('ownerId'); // 👈 رقم صاحب المحل

    if (ownerId == null || ownerId <= 0) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      snackBar(context, "بيانات صاحب المحل غير مكتملة، أعد تسجيل الدخول");
      return;
    }

    final alreadyRegistered =
        await ApiService.checkShopExistsByOwnerId(ownerId.toString());
    if (alreadyRegistered) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.go(AppRoutes.signupStep4);
      return;
    }

  // ✅ نقرأ الإحداثيات (ومع fallback على GPS إذا غير محفوظة)
  final coords = await _resolveShopCoordinates();
  final latitude = coords?.lat;
  final longitude = coords?.lng;

  if (latitude == null || longitude == null) {
    setState(() => _isLoading = false);
    await _showServiceUnavailableDialog(
      'تعذّر قراءة موقع المحل. يرجى تشغيل خدمة الموقع والمحاولة من جديد.',
    );
    return;
  }

  final areaCheck = await _checkCoverageForCoordinates(latitude, longitude);
  if (!areaCheck.isCovered || areaCheck.areaID == null) {
    setState(() => _isLoading = false);
    await _showServiceUnavailableDialog(
      areaCheck.errorMessage ?? 'عذراً، الخدمة غير متوفرة في منطقتك حالياً.',
    );
    return;
  }

  final detectedAreaId = areaCheck.areaID!;
  final detectedAreaName = areaCheck.areaName ?? '';

  String? coverBase64 = await ImageCompressor.compressFile(coverImage);
String? logoBase64 = await ImageCompressor.compressFile(logoImage);
  // ✅ تجهيز أوقات الدوام
  List<Map<String, dynamic>> hours = [];
  for (final day in days) {
    hours.add({
      "dayOfWeek": day,
      "openTime": openControllers[day]?.text ?? '',
      "closeTime": closeControllers[day]?.text ?? '',
      "isClosed": holiday[day] ?? false,
    });
  }

  final data = {
    "shopName": shopName,
    "address": address,
    "latitude": latitude,
    "longitude": longitude,
    "areaID": detectedAreaId,
    "areaName": detectedAreaName,
    "AreaID": detectedAreaId,
    "AreaName": detectedAreaName,
    "detailes": detailes,
    "categoryId": categoryId,
    "shopOwnerId": ownerId,
    "shopPhones": phones, // ✅ إرسال القائمة كاملة بدل phoneNumber
    "shopImageBase64": coverBase64,
    "shopImage2Base64": logoBase64,
    "hours": hours,
    "monthlyDue": 0,
    "dueMonth": "",
  };

  // 👇 الآن الدالة ترجع Map من السيرفر
  final response = await ApiService.completeShopRegistration(data);

  setState(() => _isLoading = false);

  if (response != null && response['success'] != false) {
    // البحث عن shopId بمختلف أشكاله الممكنة من السيرفر
    final rawShopId = response['shopId'] ?? response['ShopId'] ?? response['shop_id'] ?? response['id'];
    if (rawShopId != null) {
      final shopId = rawShopId is int ? rawShopId : int.tryParse(rawShopId.toString()) ?? 0;
      await prefs.setInt('shopId', shopId);
      print("💾 Saved shopId: $shopId");
    }
    await prefs.setInt('areaID', detectedAreaId);
    if (detectedAreaName.isNotEmpty) {
      await prefs.setString('areaName', detectedAreaName);
    }

    if (!mounted) return;
    snackBar(context, response['message'] ?? "تم التسجيل بنجاح");
    context.go(AppRoutes.signupStep4);
  } else {
    snackBar(context, response?['message']?.toString() ?? "فشل تسجيل المحل");
  }
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/altalLogo.png', fit: BoxFit.cover),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "انضم لنا الآن",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "صور وأوقات الدوام",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // أزرار الصور تبقى كما هي
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(true),
                          icon: Icon(Icons.image,
                              color: coverImage == null
                                  ? Color(0xFF5A9BD5)
                                  : Colors.white),
                          label: Text("صورة غلاف",
                              style: TextStyle(
                                  color: coverImage == null
                                      ? Color(0xFF5A9BD5)
                                      : Colors.white)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                coverImage == null ? Colors.white : Color(0xFF5A9BD5),
                            side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(false),
                          icon: Icon(Icons.photo,
                              color: logoImage == null
                                  ? Color(0xFF5A9BD5)
                                  : Colors.white),
                          label: Text("لوغو",
                              style: TextStyle(
                                  color: logoImage == null
                                      ? Color(0xFF5A9BD5)
                                      : Colors.white)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                logoImage == null ? Colors.white : Color(0xFF5A9BD5),
                            side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // جدول الأيام
                  Row(
                    children: const [
                      SizedBox(
                          width: 70,
                          child: Text("اليوم",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Center(
                              child: Text("فتح",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(
                          child: Center(
                              child: Text("إغلاق",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                      SizedBox(
                          width: 70,
                          child: Center(
                              child: Text("عطلة",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Column(
                    children: days.map((day) {
                      final isHoliday = holiday[day] ?? false;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 70,
                                child: Text(day,
                                    style: const TextStyle(fontSize: 14))),
                            const SizedBox(width: 4),
                            Expanded(
                              child: isHoliday
                                  ? const SizedBox()
                                  : TextField(
                                      controller: openControllers[day],
                                      readOnly: true,
                                      textAlign: TextAlign.center,
                                      onTap: () =>
                                          _pickTime(context, openControllers[day]!),
                                      // ✅ بدون شكل مخصص → يأخذ الثيم الأساسي
                                      decoration: const InputDecoration(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: isHoliday
                                  ? const SizedBox()
                                  : TextField(
                                      controller: closeControllers[day],
                                      readOnly: true,
                                      textAlign: TextAlign.center,
                                      onTap: () =>
                                          _pickTime(context, closeControllers[day]!),
                                      // ✅ بدون شكل مخصص → يأخذ الثيم الأساسي
                                      decoration: const InputDecoration(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 70,
                              child: Center(
                                child: Checkbox(
                                  shape: const CircleBorder(),
                                  value: isHoliday,
                                  onChanged: (val) {
                                    setState(() {
                                      holiday[day] = val ?? false;
                                    });
                                  },
                                  activeColor: Color(0xFF5A9BD5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 100), // مساحة إضافية فوق الزر المثبت
                ],
              ),
            ),
          ),
        ],
      ),
    ),

    // ✅ زر مثبت في الأسفل ويأخذ الثيم من AppTheme
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isLoading ? null : _submitShop,
          child: _isLoading
              ? const LoadingDotsWidget()
              : const Text("تسجيل"),
        ),
      ),
    ),
  );
}
}

class _MapPoint {
  final double lat;
  final double lng;

  const _MapPoint({required this.lat, required this.lng});
}

class _AreaCheckResult {
  final bool isCovered;
  final int? areaID;
  final String? areaName;
  final String? errorMessage;

  const _AreaCheckResult({
    required this.isCovered,
    this.areaID,
    this.areaName,
    this.errorMessage,
  });
}

class _LocationCoords {
  final double lat;
  final double lng;

  const _LocationCoords({required this.lat, required this.lng});
}
