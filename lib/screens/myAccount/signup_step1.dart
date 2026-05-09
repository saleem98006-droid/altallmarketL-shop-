import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // للغباش
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:location/location.dart';
import 'dart:convert';

import '../snackBar/snackbar.dart';
import '../../widgets/loading_dots_widget.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import '../../providers/router_provider.dart';



class SignupStep1 extends StatefulWidget {
  const SignupStep1({super.key});

  @override
  State<SignupStep1> createState() => _SignupStep1State();
}

class _SignupStep1State extends State<SignupStep1> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes; // للعرض في الواجهة
File? _imageFile;       // للإرسال إلى السيرفر

  final nameFocus = FocusNode();
  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();
  final confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<_AreaCheckResult> _checkCoverageForCurrentLocation() async {
    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return const _AreaCheckResult(
            isCovered: false,
            errorMessage: 'يرجى تشغيل خدمة الموقع (GPS) ثم المحاولة من جديد.',
          );
        }
      }

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
      }

      if (permission == PermissionStatus.denied ||
          permission == PermissionStatus.deniedForever) {
        return const _AreaCheckResult(
          isCovered: false,
          errorMessage: 'نحتاج إذن الموقع للتحقق من منطقة الخدمة.',
        );
      }

      final locationData = await location.getLocation();
      final lat = locationData.latitude;
      final lng = locationData.longitude;

      if (lat == null || lng == null) {
        return const _AreaCheckResult(
          isCovered: false,
          errorMessage: 'تعذّر قراءة موقعك الحالي. حاول مرة أخرى.',
        );
      }

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
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameFocus.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    confirmFocus.dispose();
    super.dispose();
  }

  // ✅ دالة لتنسيق الحقول
 InputDecoration _inputDecoration(
  String label,
  FocusNode focusNode,
  TextEditingController controller, {
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: prefixIcon == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(width: 24, height: 24, child: prefixIcon),
          ),
    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFF5A9BD5), width: 2.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFF5A9BD5), width: 3.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFF5A9BD5), width: 1),
    ),
  );
}
Future<void> _pickImage() async {
  final picker = ImagePicker();
 final pickedFile = await picker.pickImage(source: ImageSource.gallery);

if (pickedFile != null) {
  final file = File(pickedFile.path);
  final bytes = await file.readAsBytes();

  setState(() {
    _imageFile = file;   // نستخدمه للإرسال
    _imageBytes = bytes; // نستخدمه للعرض
  });
}
} 

  Future<void> _registerOwner() async {
        final name = nameController.text.trim();
        final phone = phoneController.text.trim();
        final email = emailController.text.trim();
        final password = passwordController.text.trim();
        final confirm = confirmPasswordController.text.trim();

        // ✅ استخدم الـ validator بدل الشرط اليدوي
        if (!_formKey.currentState!.validate()) {
          return;
        }

        // ✅ تحقق من رقم الهاتف
        if (!(phone.length == 10 && phone.startsWith("09"))) {
          snackBar(context, "رقم الهاتف يجب أن يكون 10 أرقام ويبدأ بـ 09");
          return;
        }

        if (password != confirm) {
          snackBar(context, "كلمتا المرور غير متطابقتين");
          return;
        }

        setState(() => _isLoading = true);

        final areaCheck = await _checkCoverageForCurrentLocation();
        if (!areaCheck.isCovered || areaCheck.areaID == null) {
          setState(() => _isLoading = false);
          await _showServiceUnavailableDialog(
            areaCheck.errorMessage ?? 'عذراً، الخدمة غير متوفرة في منطقتك حالياً.',
          );
          return;
        }

        final response = await ApiService.registerOwner(
  fullName: name,
  phoneNumber: phone,
  email: email,
  password: password,
  profileImage: _imageFile, // ممكن تكون null
);

        setState(() => _isLoading = false);

        if (response == null || response['success'] != true) {
          snackBar(context, response?['message'] ?? "فشل التسجيل، حاول مرة أخرى");
          return;
        }

        // ✅ نجاح التسجيل
      

        // ✅ استخراج رقم صاحب المحل كـ int مباشرة
        final int ownerId = response['shopOwnerId'];

        // ✅ الحصول على FCM Token
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          // حفظ التوكين في السيرفر
          await ApiService.saveUserToken(
            userType: "Shop",
            userId: ownerId, // 👈 الآن int مباشرة
            fcmToken: fcmToken,
          );

          // ✅ حفظ البيانات محليًا
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('ownerId', ownerId); // 👈 حفظ كـ int
          await prefs.setString('phoneNumber', phone);
          await prefs.setString('fullName', name);
          await prefs.setString('fcmToken', fcmToken); // 👈 حفظ التوكين محليًا أيضًا
          await prefs.setBool('isLoggedIn', true);
          await prefs.setBool('isApproved', false);
          await prefs.setBool('isActive', true);
          await prefs.setInt('areaID', areaCheck.areaID!);
          if ((areaCheck.areaName ?? '').isNotEmpty) {
            await prefs.setString('areaName', areaCheck.areaName!);
          }

          print("💾 Saved ownerId: $ownerId");
          print("💾 Saved fcmToken: $fcmToken");
        }

        if (!mounted) return;
          snackBar(context, response['message'] ?? "تم التسجيل بنجاح");
        context.go(AppRoutes.signupStep2);
}
 

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية
          Image.asset('assets/images/altalLogo.png', fit: BoxFit.cover),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.white.withOpacity(0.35)),
            ),
          ),

          // المحتوى
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'انضم لنا الآن',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  ' معلومات صاحب المحل',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 20),

                // النموذج
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // صورة البروفايل
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF5A9BD5), width: 2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: _imageBytes == null
                              ? const Center(
                                  child: Text(
                                    "اختر صورة",
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      color: Colors.black54,
                                    ),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // الاسم
                      TextFormField(
                        controller: nameController,
                        focusNode: nameFocus,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          "الاسم",
                          nameFocus,
                          nameController,
                          prefixIcon: Image.asset("assets/images/account.png", fit: BoxFit.contain),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                      ),
                      const SizedBox(height: 16),

                      // رقم الهاتف
                      TextFormField(
                        controller: phoneController,
                        focusNode: phoneFocus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          "رقم الهاتف",
                          phoneFocus,
                          phoneController,
                          prefixIcon: Image.asset("assets/images/phone.png", fit: BoxFit.contain),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                      ),
                      const SizedBox(height: 16),

                      // البريد الإلكتروني
                      TextFormField(
                        controller: emailController,
                        focusNode: emailFocus,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          "البريد الإلكتروني",
                          emailFocus,
                          emailController,
                          prefixIcon: Image.asset("assets/images/email.png", fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // كلمة المرور
                      TextFormField(
                        controller: passwordController,
                        focusNode: passFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          "كلمة المرور",
                          passFocus,
                          passwordController,
                          prefixIcon: const Icon(Icons.lock, color: Colors.black, size: 24),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                      ),
                      const SizedBox(height: 16),

                      // تأكيد كلمة المرور
                      TextFormField(
                        controller: confirmPasswordController,
                        focusNode: confirmFocus,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          "تأكيد كلمة المرور",
                          confirmFocus,
                          confirmPasswordController,
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.black, size: 24),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                      ),
                      const SizedBox(height: 30),

                      // زر التالي
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _registerOwner,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF5A9BD5), width: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const LoadingDotsWidget()
                              : const Text(
                                  "التالي",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
