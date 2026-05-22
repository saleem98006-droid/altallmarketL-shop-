import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dio_service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class _ApiResponse {
  final int statusCode;
  final String body;

  const _ApiResponse({required this.statusCode, required this.body});
}

class DioTransport {
  static _ApiResponse _toApiResponse(Response response) {
    final data = response.data;
    final responseBody = data is String ? data : jsonEncode(data);
    return _ApiResponse(
      statusCode: response.statusCode ?? 500,
      body: responseBody,
    );
  }

  static Future<_ApiResponse> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await DioService.instance.getUri(
        url,
        options: Options(headers: headers),
      );
      return _toApiResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return _toApiResponse(e.response!);
      }
      rethrow;
    }
  }

  static Future<_ApiResponse> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await DioService.instance.postUri(
        url,
        data: body,
        options: Options(headers: headers),
      );
      return _toApiResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return _toApiResponse(e.response!);
      }
      rethrow;
    }
  }

  static Future<_ApiResponse> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await DioService.instance.putUri(
        url,
        data: body,
        options: Options(headers: headers),
      );
      return _toApiResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return _toApiResponse(e.response!);
      }
      rethrow;
    }
  }

  static Future<_ApiResponse> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await DioService.instance.deleteUri(
        url,
        options: Options(headers: headers),
      );
      return _toApiResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return _toApiResponse(e.response!);
      }
      rethrow;
    }
  }
}

class ApiService {
  // 🔍 التحقق من حالة صاحب المحل
  static Future<Map<String, dynamic>> checkOwnerStatus(String phone) async {
  try {
    final response = await DioService.get(
      "/shops/status",
      params: {"phone": phone},
    );

    if (response.statusCode == 200) {
      return {
        "success": true,
        "data": response.data,
      };
    }

    return {"success": false, "error": "خطأ غير متوقع"};
  } catch (e) {
    print("❌ Dio checkOwnerStatus Error: $e");

    return {
      "success": false,
      "error": "network_error",
    };
  }
}

  //التحقق من توفر تحديث للتطبيق
  static Future<Map<String, dynamic>?> checkAppUpdate(
    String platform, {
    String appKey = 'shop',
  }) async {
    try {
      final response = await DioService.get(
        '/AppUpdate/check',
        params: {
          'platform': platform,
          'appKey': appKey,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // 🟢 جلب المناطق (للتحقق من التغطية أثناء تسجيل المحل)
  static Future<List<Map<String, dynamic>>?> getAreas() async {
    try {
      final response = await DioService.get('/Manager/get-areas');

      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return list;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// حفظ التوكن لأول مرة
  static Future<Map<String, dynamic>?> saveUserToken({
    required String userType,
    required int userId,
    required String fcmToken,
     
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Notifications/saveUserToken');

    final body = jsonEncode({
      "UserType": userType,
      "UserID": userId,
      "FCMToken": fcmToken,
      
    });

    final response = await DioTransport.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print("❌ فشل في حفظ التوكن: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

//جلب الاشعارات من الجدول

  static Future<Map<String, dynamic>> getNotifications(
  String userType,
  int userId, {
  int page = 1,
  int pageSize = 10,
}) async {
  try {
    final response = await DioService.get(
      "/Notifications/notifications/$userType/$userId",
      params: {
        "page": page,
        "pageSize": pageSize,
      },
    );

    // نفترض أن السيرفر يرجّع Map<String, dynamic>
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    // لو رجّع شيء غير متوقع
    return {
      "success": false,
      "message": "استجابة غير صالحة من السيرفر",
    };
  } catch (e) {
    //print("❌ Dio getNotifications Error: $e");
    return {
      "success": false,
      "message": "خطأ في الاتصال بالسيرفر",
    };
  }
}

  //تحديث حالة الاشعار الى مقروء
  static Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/Notifications/notifications/markAsRead/$notificationId');

  final response = await DioTransport.post(
    url,
    headers: {"Content-Type": "application/json"},
  );

  try {
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  } catch (e) {
    return {
      "success": false,
      "message": "خطأ في الاتصال بالسيرفر أو استجابة غير صالحة"
    };
  }
}



  // 🔐 تسجيل الدخول
/*static Future<Map<String, dynamic>?> loginOwner(
  String phone,
  String password,
) async {
  try {
    final dio = DioService.instance;

    final response = await dio.post(
      "/Shops/login",  
      data: {
        "phoneNumber": phone,
        "password": password,
      },
      options: Options(
        contentType: "application/json",
      ),
    );

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }

    return {
      "isLoggedIn": false,
      "error": response.data?['message'] ?? "فشل تسجيل الدخول"
    };
  } catch (e) {
    print("❌ Dio Login Error: $e");
    return {
      "isLoggedIn": false,
      "error": "خطأ أثناء الاتصال بالسيرفر"
    };
  }
}*/
static Future<Map<String, dynamic>?> loginOwner(String phone, String password) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/shops/login');
  final response = await DioTransport.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phoneNumber': phone,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // ← يحتوي على بيانات الدخول
  } else {
    // رجع الخطأ كنص من السيرفر
    return {
      "isLoggedIn": false,
      "error": response.body.isNotEmpty ? response.body : "حدث خطأ غير متوقع"
    };
  }
}


  // 📝 تسجيل صاحب المحل
 static Future<Map<String, dynamic>?> registerOwner({
  required String fullName,
  required String phoneNumber,
  required String email,
  required String password,
  File? profileImage,
}) async {
  try {
    final dio = DioService.instance;

    FormData formData = FormData.fromMap({
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "email": email,
      "password": password,
      if (profileImage != null)
        "profileImage": await MultipartFile.fromFile(
          profileImage.path,
          filename: profileImage.path.split('/').last,
        ),
    });

    final response = await dio.post(
      "/shops/register",
      data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data as Map<String, dynamic>;
    }

    return {
      "success": false,
      "message": "فشل التسجيل، حاول مرة أخرى"
    };
  } on DioException catch (e) {
    // استخراج رسالة الخطأ الحقيقية من السيرفر
    final data = e.response?.data;
    String? serverMessage;

    if (data is Map) {
      serverMessage = (data['message'] ?? data['Message'] ??
          data['error'] ?? data['Error'])?.toString();
    } else if (data is String && data.trim().isNotEmpty) {
      serverMessage = data.trim();
    }

    return {
      "success": false,
      "message": serverMessage ?? "خطأ أثناء الاتصال بالسيرفر"
    };
  } catch (e) {
    return {
      "success": false,
      "message": "خطأ أثناء الاتصال بالسيرفر"
    };
  }
}

// 📝 تعديل بيانات صاحب المحل (بدون كلمة مرور)
static Future<Map<String, dynamic>?> updateOwner(Map<String, dynamic> data) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/shops/update');

  final response = await DioTransport.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    return null;
  }
}

// 📝 جلب بيانات صاحب المحل
static Future<Map<String, dynamic>?> getOwnerById(int ownerId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/shops/owners/$ownerId');

  final response = await DioTransport.get(
    url,
    headers: {'Content-Type': 'application/json'},
  );

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    return null;
  }
}

// 🔑 تغيير كلمة مرور صاحب المحل
static Future<Map<String, dynamic>?> changeOwnerPassword(
    int ownerId, String oldPassword, String newPassword) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/shops/owners/$ownerId/change-password');

  final response = await DioTransport.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "oldPassword": oldPassword,
      "newPassword": newPassword,
    }),
  );

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    return null;
  }
}


// 🟢 جلب بيانات محل محدد
static Future<Map<String, dynamic>?> getShopById(int shopId) async {
  try {
    final dio = DioService.instance;

    final response = await dio.get("/Shops/$shopId");

    print("GET Status: ${response.statusCode}");
    print("GET Body: ${response.data}");

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;

      // 🟢 تأكيد أن phoneNumbers قائمة نصوص
      if (data.containsKey("phoneNumbers") && data["phoneNumbers"] is List) {
        data["phoneNumbers"] =
            List<String>.from(data["phoneNumbers"].map((e) => e.toString()));
      } else {
        data["phoneNumbers"] = <String>[];
      }

        // 🟢 حقول الدولار (مع fallback بين صيغ المفاتيح)
        final hasDollarKey =
          data.containsKey("isDollarEnabled") || data.containsKey("IsDollarEnabled");
        final rawDollar = data["isDollarEnabled"] ?? data["IsDollarEnabled"];
      final rawRate = data["exchangeRate"] ?? data["ExchangeRate"];

        if (hasDollarKey) {
        data["isDollarEnabled"] = rawDollar == true ||
          rawDollar.toString().trim().toLowerCase() == 'true' ||
          rawDollar.toString().trim() == '1';
        }
      data["exchangeRate"] =
          rawRate == null ? null : double.tryParse(rawRate.toString());

      return data;
    }

    return null;
  } catch (e) {
    print("❌ خطأ في getShopById: $e");
    return null;
  }
}

// 🟡 تعديل بيانات محل
static Future<Map<String, dynamic>?> updateShop({
  required int shopId,
  String? shopName,
  String? address,
  String? detailes,
  File? shopImage,
  File? shopImage2,
  List<String>? phoneNumbers,
  bool? isDollarEnabled,
}) async {
  try {
    final dio = DioService.instance;

    // 🟢 تجهيز FormData
    FormData formData = FormData.fromMap({
      if (shopName != null) "shopName": shopName,
      if (address != null) "address": address,
      if (detailes != null) "detailes": detailes,
      if (isDollarEnabled != null) "isDollarEnabled": isDollarEnabled,

      // 🟢 إرسال أرقام الهواتف كـ JSON string
      "phoneNumbersJson": phoneNumbers != null
          ? jsonEncode(phoneNumbers)
          : jsonEncode([]),

      // 🟢 إرسال الصور كملفات
      if (shopImage != null)
        "shopImage": await MultipartFile.fromFile(
          shopImage.path,
          filename: shopImage.path.split('/').last,
        ),

      if (shopImage2 != null)
        "shopImage2": await MultipartFile.fromFile(
          shopImage2.path,
          filename: shopImage2.path.split('/').last,
        ),
    });

    final response = await dio.put(
      "/Shops/$shopId",
      data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );

    print("PUT Status: ${response.statusCode}");
    print("PUT Body: ${response.data}");

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }

    return {
      "status": false,
      "message": "فشل التعديل"
    };
  } catch (e) {
    print("❌ Dio UpdateShop Error: $e");
    return {
      "status": false,
      "message": "خطأ أثناء الاتصال بالسيرفر"
    };
  }
}

// 💵 جلب/تعديل سعر الصرف للمحل
static Future<Map<String, dynamic>?> getOrUpdateExchangeRate({
  required int shopId,
  double? newExchangeRate,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/shops/exchangeRate');

  final body = <String, dynamic>{
    "shopId": shopId,
    if (newExchangeRate != null) "newExchangeRate": newExchangeRate,
  };

  final response = await DioTransport.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  return null;
}

// 🟣 تعديل أوقات الدوام
static Future<Map<String, dynamic>?> updateShopHours(
    int shopId, List<Map<String, dynamic>> hours) async {
  
  final url = Uri.parse('${ApiConfig.baseUrl}/Shops/hours/update');

  // 🟢 تجهيز البيانات للإرسال
  final data = {
    "shopId": shopId,
    "hours": hours,
  };

  final response = await DioTransport.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  print('UPDATE HOURS Status: ${response.statusCode}');
  print('UPDATE HOURS Body: ${response.body}');

  if (response.statusCode == 200) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {"message": response.body};
    }
  } else {
    return null;
  }
}

//جلب اوقات الدوام
static Future<List<dynamic>?> getShopHours(int shopId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/Shops/shopDetails/$shopId');

  final response = await DioTransport.get(url);

  print("GET SHOP DETAILS Status: ${response.statusCode}");
  print("GET SHOP DETAILS Body: ${response.body}");

  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);

      // 🟢 التأكد أن workHours موجودة
      if (data is Map<String, dynamic> && data.containsKey("workHours")) {
        return data["workHours"] as List<dynamic>;
      }

      return null;
    } catch (e) {
      print("❌ JSON Parse Error: $e");
      return null;
    }
  }

  return null;
}






  // 🏪 تسجيل بيانات المحل بالكامل
  static Future<Map<String, dynamic>?> completeShopRegistration(Map<String, dynamic> data) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/shops/registration');

  try {
    final response = await DioService.instance.postUri(
      url,
      data: jsonEncode(data),
      options: Options(
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    print("Status: ${response.statusCode}");
    print("Body: ${response.data}");

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
      return {
        'success': true,
        'message': 'تم التسجيل بنجاح',
      };
    }

    return {
      'success': false,
      'message': 'فشل تسجيل المحل',
    };
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return {
        'success': false,
        'message': 'انتهت مهلة الاتصال بالسيرفر، حاول مرة أخرى',
      };
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return {
        'success': false,
        'message': (data['message'] ?? data['error'] ?? 'فشل تسجيل المحل').toString(),
      };
    }

    return {
      'success': false,
      'message': 'حدث خطأ أثناء تسجيل المحل',
    };
  } catch (_) {
    return {
      'success': false,
      'message': 'حدث خطأ غير متوقع أثناء تسجيل المحل',
    };
  }
}


  // 🔍 التحقق من وجود محل مرتبط بصاحب المحل
  static Future<bool> checkShopExistsByOwnerId(String ownerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops?ownerId=$ownerId');
    try {
      final response = await DioTransport.get(url);

      print('🔍 Checking shop for ownerId: $ownerId');
      print('📦 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data != null && data.isNotEmpty;
      }

      return false;
    } on DioException catch (e) {
      print('⚠️ checkShopExistsByOwnerId DioException: $e');
      return false;
    } on SocketException catch (e) {
      print('⚠️ checkShopExistsByOwnerId SocketException: $e');
      return false;
    } on HttpException catch (e) {
      print('⚠️ checkShopExistsByOwnerId HttpException: $e');
      return false;
    } catch (e) {
      print('⚠️ checkShopExistsByOwnerId error: $e');
      return false;
    }
  }

  // 📂 جلب جميع الفئات
  /*static Future<List<dynamic>?> getCategories() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops/categories');
    final response = await DioTransport.get(url);

    print('📂 Fetching categories...');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['categories']; // ← يرجع المصفوفة فقط
    } else {
      return null;
    }
  }*/
  static Future<List<dynamic>?> getCategories() async {
  final url = Uri.parse('${ApiConfig.baseUrl}/shops/categoriesNames');
  final response = await DioTransport.get(url);

  print('📂 Fetching category names...');
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['categories']; // ← يرجع فقط المصفوفة
  } else {
    return null;
  }
}

  // ➕ إضافة منتج
static Future<Map<String, dynamic>?> addProduct(
  Map<String, dynamic> productData, {
  String? idempotencyKey,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/addProduct');

  final payload = Map<String, dynamic>.from(productData);
  final trimmedKey = idempotencyKey?.trim();
  if (trimmedKey != null && trimmedKey.isNotEmpty) {
    // مفاتيح متوافقة مع أكثر من باك إند
    payload['requestId'] = trimmedKey;
    payload['clientRequestId'] = trimmedKey;
  }

  final headers = <String, String>{'Content-Type': 'application/json'};
  if (trimmedKey != null && trimmedKey.isNotEmpty) {
    headers['Idempotency-Key'] = trimmedKey;
    headers['X-Idempotency-Key'] = trimmedKey;
  }

  final response = await DioTransport.post(
    url,
    headers: headers,
    body: jsonEncode(payload),
  );

  print('📦 AddProduct Status: ${response.statusCode}');
  print('📦 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

// ✏️ تعديل منتج
static Future<bool> updateProduct(
  int productId,
  Map<String, dynamic> data, {
  File? image1File,
  File? image2File,
  File? image3File,
}) async {
  try {
    final dio = DioService.instance;
    final payload = Map<String, dynamic>.from(data);

    // 🔥 تنظيف القيم قبل إرسالها
    payload["imageUrl1"] =
        (payload["imageUrl1"] == null || payload["imageUrl1"].toString().trim().isEmpty)
            ? null
            : payload["imageUrl1"];

    payload["imageUrl2"] =
        (payload["imageUrl2"] == null || payload["imageUrl2"].toString().trim().isEmpty)
            ? null
            : payload["imageUrl2"];

    payload["imageUrl3"] =
        (payload["imageUrl3"] == null || payload["imageUrl3"].toString().trim().isEmpty)
            ? null
            : payload["imageUrl3"];

    FormData formData = FormData.fromMap({
      "productName": payload["productName"],
      "description": payload["description"],
      if (payload["price"] != null) "price": payload["price"].toString(),
      if (payload["priceUSD"] != null)
        "priceUSD": payload["priceUSD"].toString(),
      "sectionId": payload["sectionId"]?.toString(),

      // 🔥 إرسال المفاتيح دائمًا
      "imageUrl1": payload["imageUrl1"],
      "imageUrl2": payload["imageUrl2"],
      "imageUrl3": payload["imageUrl3"],

      if (image1File != null)
        "image1File": await MultipartFile.fromFile(
          image1File.path,
          filename: image1File.path.split('/').last,
        ),

      if (image2File != null)
        "image2File": await MultipartFile.fromFile(
          image2File.path,
          filename: image2File.path.split('/').last,
        ),

      if (image3File != null)
        "image3File": await MultipartFile.fromFile(
          image3File.path,
          filename: image3File.path.split('/').last,
        ),
    });

    print("📦 FormData fields:");
    formData.fields.forEach((f) => print("  ${f.key}: ${f.value}"));

    print("📸 FormData files:");
    formData.files.forEach((f) => print("  ${f.key}: ${f.value.filename}"));

    final response = await dio.put(
      "/products/updateProduct/$productId",
      data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );

    print("PUT Status: ${response.statusCode}");
    print("PUT Body: ${response.data}");

    if (response.statusCode == 200 && response.data["success"] == true) {
      return true;
    }

    return false;
  } catch (e) {
    print("❌ Update Product Error: $e");
    return false;
  }
}

// 🗑️ حذف منتج
static Future<Map<String, dynamic>?> deleteProduct(int productId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/deleteProduct/$productId');
  final response = await DioTransport.delete(url);

  print('🗑️ DeleteProduct Status: ${response.statusCode}');
  print('🗑️ Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}


// ➕ إضافة خصم
static Future<Map<String, dynamic>?> addDiscount(Map<String, dynamic> discountData) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/addDiscount');
  final response = await DioTransport.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(discountData),
  );

  print('📦 AddDiscount Status: ${response.statusCode}');
  print('📦 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

// ➕ إضافة عرض
static Future<Map<String, dynamic>?> addOffer(Map<String, dynamic> offerData) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/addOffer');
  final response = await DioTransport.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(offerData),
  );

  print('📦 AddOffer Status: ${response.statusCode}');
  print('📦 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}



// 🏪 جلب منتجات محل
static Future<List<Map<String, dynamic>>?> getProductsByShop(int shopId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/getProductsByShop/$shopId');
  final response = await DioTransport.get(url);

  print('📦 GetProductsByShop Status: ${response.statusCode}');
  print('📦 Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['products']);
  } else {
    return null;
  }
}

 // 🎁 جلب العروض الفعّالة لمحل محدد
static Future<List<Map<String, dynamic>>?> getActiveOffersByShop(int shopId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/getActiveOffersByShop/$shopId');
  final response = await DioTransport.get(url);

  print('🎁 GetActiveOffersByShop Status: ${response.statusCode}');
  print('🎁 Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['offers']);
  } else {
    return null;
  }
}

// 💸 جلب الخصومات الفعّالة لمحل محدد
static Future<List<Map<String, dynamic>>?> getActiveDiscountsByShop(int shopId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/getActiveDiscountsByShop/$shopId');
  final response = await DioTransport.get(url);

  print('💸 GetActiveDiscountsByShop Status: ${response.statusCode}');
  print('💸 Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['discounts']);
  } else {
    return null;
  }
}


// ✏️ تعديل سعر منتج
static Future<Map<String, dynamic>?> updateProductPrice(
  int productId, {
  double? price,
  double? priceUSD,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/updatePrice/$productId');

  final payload = <String, dynamic>{
    if (price != null) "price": price,
    if (priceUSD != null) "priceUSD": priceUSD,
  };

  if (payload.isEmpty) {
    return null;
  }

  final response = await DioTransport.put(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(payload),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

// 🗂️ جلب كل الأقسام مع منتجاتها (مع دعم Pagination)
static Future<Map<String, dynamic>?> getSectionsWithProducts(
  int shopId, {
  required int page,
  required int pageSize,
  required int productPageSize,
}) async {
  try {
    final dio = DioService.instance;

    final response = await dio.get(
      "/Products/getSectionsWithProducts",
      queryParameters: {
        "shopId": shopId,
        "page": page,
        "pageSize": pageSize,
        "productPageSize": productPageSize,
      },
    );

    print("🗂️ Status: ${response.statusCode}");
    print("🗂️ Body: ${response.data}");

    if (response.statusCode == 200) {
      final data = response.data;

      if (data["success"] == true) {
        return data; // يحتوي sections + page + pageSize + productPageSize
      }
    }

    print("❌ فشل في تحميل الأقسام: ${response.data}");
    return null;
  } catch (e) {
    print("❌ خطأ في الاتصال بالسيرفر: $e");
    return null;
  }
}
///جلب جميع اقسام المحل
static Future<Map<String, dynamic>?> getSectionsShop(int shopId) async {
  try {
    final response = await DioService.get(
      "/products/getSectionsShop/$shopId",
    );

    // print("📘 GetSectionsShop Status: ${response.statusCode}");
    // print("📘 Body: ${response.data}");

    return response.data;
  } catch (e) {
    // print("❌ ERROR getSectionsShop: $e");
    return null;
  }
}

//جلب الاقسام مع منتجاتها فقط السعر والاسم
static Future<Map<String, dynamic>?> getSectionsWithProductsLite(int shopId) async {
  final url = Uri.parse(
    '${ApiConfig.baseUrl}/products/getSectionsWithProductsLite/$shopId',
  );

  final response = await DioTransport.get(url);

  print('🗂️ GetSectionsWithProductsLite Status: ${response.statusCode}');
  print('🗂️ Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//تحميل المنتجات بالتدريج حسب القسم
static Future<Map<String, dynamic>?> getMoreProducts({
  required int sectionId,
  required int page,
  required int pageSize,
}) async {
  final url = Uri.parse(
    '${ApiConfig.baseUrl}/products/getMoreProducts'
    '?sectionId=$sectionId'
    '&page=$page'
    '&pageSize=$pageSize',
  );

  final response = await DioTransport.get(url);

  print('➡️ GetMoreProducts Status: ${response.statusCode}');
  print('➡️ Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}


//عرض عناصر الطلب داخل محل
static Future<Map<String, dynamic>?> getShopOrderItemsByShopOrder({
  required int shopOrderId,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/Orders/getShopOrderItemsByShopOrder?shopOrderId=$shopOrderId');

  print("[DEBUG] Request URL: $url");

  final response = await DioTransport.get(url, headers: {"Content-Type": "application/json"});

  print("[DEBUG] Response status: ${response.statusCode}");
  print("[DEBUG] Response raw: ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    return null;
  }
}

//جلب المنتج او العرض حسب المصدر داخل عناصر طلب المحل
static Future<Map<String, dynamic>?> getItemDetails({
  required int sourceId,
  required String sourceType,
}) async {
  final url = Uri.parse(
      '${ApiConfig.baseUrl}/Orders/getItemDetails?sourceId=$sourceId&sourceType=$sourceType');

  print("[DEBUG] Request URL: $url");

  final response = await DioTransport.get(
    url,
    headers: {"Content-Type": "application/json"},
  );

  print("[DEBUG] Response status: ${response.statusCode}");
  print("[DEBUG] Response raw: ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    return null;
  }
}

// 🛒 جلب المنتجات غير المرتبطة بأي قسم
static Future<Map<String, dynamic>?> getUncategorizedProducts(int shopId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/getUncategorizedProducts/$shopId');
  final response = await DioTransport.get(url);

  print('🛒 GetUncategorizedProducts Status: ${response.statusCode}');
  print('🛒 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}




// 💰 جلب سعر منتج محدد
static Future<Map<String, dynamic>?> getProductPrice(int productId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/getProductPrice/$productId');
  final response = await DioTransport.get(url);

  print('💰 GetProductPrice Status: ${response.statusCode}');
  print('💰 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//جلب الاقسام لمحل 
static Future<Map<String, dynamic>?> getSectionsByShop(int shopId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/getSectionsByShop/$shopId');
  final response = await DioTransport.get(url);

  print('📂 GetSectionsByShop Status: ${response.statusCode}');
  print('📂 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//اضافة قسم لمحل
static Future<Map<String, dynamic>?> addSection(int shopId, String sectionName, String? description) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/addSection');
  final body = jsonEncode({
    "shopId": shopId,
    "sectionName": sectionName,
    "description": description
  });

  final response = await DioTransport.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  print('➕ AddSection Status: ${response.statusCode}');
  print('➕ Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//تعديل قسم لمحل
static Future<Map<String, dynamic>?> updateSection(int sectionId, String sectionName, String? description) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/updateSection/$sectionId');
  final body = jsonEncode({
    "sectionName": sectionName,
    "description": description
  });

  final response = await DioTransport.put(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  print('✏️ UpdateSection Status: ${response.statusCode}');
  print('✏️ Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//حذف قسم لمحل مع حذف المنتجات المرتبطة به 
static Future<Map<String, dynamic>?> deleteSection(int sectionId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/deleteSection/$sectionId');
  final response = await DioTransport.delete(url);

  print('❌ DeleteSection Status: ${response.statusCode}');
  print('❌ Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//جلب المنتجات لقسم معين
static Future<Map<String, dynamic>?> getProductsBySection(int shopId, int sectionId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/getProductsBySection/$shopId/$sectionId');
  final response = await DioTransport.get(url);

  print('🛒 GetProductsBySection Status: ${response.statusCode}');
  print('🛒 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

 // 🟢 دالة مساعدة لعرض رسالة خطأ
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("خطأ"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("موافق"),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  

  // 🟢 3. الأكشن الموحّد
  static Future<Map<String, dynamic>?> sendAndDistribute(
      BuildContext context, int shopId, Map<String, dynamic> bodyData) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Notifications/sendAndDistribute');
    final body = jsonEncode(bodyData);

    try {
      final response = await DioTransport.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print('🚀 SendAndDistribute Status: ${response.statusCode}');
      print('🚀 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        showErrorDialog(context, "فشل إرسال وتوزيع الإشعار: ${response.body}");
        return null;
      }
    } catch (e) {
      showErrorDialog(context, "حدث خطأ في الاتصال: $e");
      return null;
    }
  }

   /// 🗂️ جلب مجموع المسحوبات لكل زبون في محل معيّن
 static Future<List<dynamic>?> getWithdrawalsSummary(int shopId, String filter) async {
  final url = Uri.parse(
    '${ApiConfig.baseUrl}/customers/getWithdrawalsSummary/$shopId?filter=$filter',
  );

  final response = await DioTransport.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['withdrawals']; // قائمة الزبائن مع مجموع السحب
    }
  }
  return null;
}

  /// 📋 جلب تفاصيل السحوبات لزبون معيّن
  static Future<List<dynamic>?> getCustomerWithdrawals(
    int shopId, int customerId, String filter) async {

  final url = Uri.parse(
    '${ApiConfig.baseUrl}/customers/getCustomerWithdrawals/$shopId/$customerId?filter=$filter',
  );

  final response = await DioTransport.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['withdrawals'];
    }
  }
  return null;
}

  /// 📊 جلب تفاصيل المستحقات الشهرية للمحل
  static Future<Map<String, dynamic>?> getShopMonthlyPayments(int shopId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/Manager/getShopMonthlyPayments?shopId=$shopId',
    );

    final response = await DioTransport.get(url);

    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    }

    return null;
  }

  /// 📊 جلب كشف المستحقات الشهري للمحل (shopId + month)
  static Future<Map<String, dynamic>?> getShopMonthlyStatement({
    required int shopId,
    required int month,
  }) async {
    // المسار الصحيح حسب السيرفر: controller = shops, action = monthlyStatement
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/shops/monthlyStatement?shopId=$shopId&month=$month',
    );

    final response = await DioTransport.get(url);

    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
    }

    return null;
  }


 // 🟢 إضافة اقتراح جديد
 static Future<Map<String, dynamic>?> addSuggestion({
  required String submittedByType,
  required int submittedById,
  required String title,
  required String message,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/Suggestions/addSuggestion');

  final response = await DioTransport.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "submittedByType": submittedByType,
      "submittedById": submittedById,
      "title": title,
      "message": message,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    print("⚠️ فشل إضافة الاقتراح: ${response.body}");
    return null;
  }
}

//اضافة شكوى
static Future<Map<String, dynamic>?> addComplaint({
  required String submittedByType,
  required int submittedById, 
  required String title,
  required String message,
  String? relatedEntity,   // اختياري
  int? relatedId,          // اختياري
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/Complaints/addComplaint');

  final body = {
    "submittedByType": submittedByType,
    "submittedById": submittedById,
    "title": title,
    "message": message,
  };

  // نضيف الحقول الاختيارية إذا موجودة
  if (relatedEntity != null) body["relatedEntity"] = relatedEntity;
  if (relatedId != null) body["relatedId"] = relatedId;

  final response = await DioTransport.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    print("⚠️ فشل إضافة الشكوى: ${response.body}");
    return null;
  }
}


//عرض صفحة حول الفيرجين
static Future<Map<String, dynamic>?> getAppVersionByName(String appName) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/AppInfo/getAppVersionByName/$appName');

  final response = await DioTransport.get(url, headers: {
    "Content-Type": "application/json",
  });

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    print("⚠️ فشل جلب إصدار التطبيق: ${response.body}");
    return null;
  }
}

// عرض صفحة حول المعلومات
static Future<Map<String, dynamic>?> getAppInfo({String language = "ar"}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/AppInfo/getAppInfo?language=$language');

  final response = await DioTransport.get(url, headers: {
    "Content-Type": "application/json",
  });

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    print("⚠️ فشل جلب معلومات التطبيق: ${response.body}");
    return null;
  }
}

// اضافة سلايدر
static Future<Map<String, dynamic>> addSlider(Map<String, dynamic> sliderData) async {
  final url = Uri.parse("${ApiConfig.baseUrl}/sliders/addSlider"); // ✅ نفس اسم الأكشن في الكنترولر
  final response = await DioTransport.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(sliderData),
  );

  // إذا رجع السيرفر رد JSON (نجاح أو خطأ)
  if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 400) {
    try {
      final result = jsonDecode(response.body);
      return {
        "success": result["success"] ?? false,
        "message": result["message"] ?? "⚠️ لم يتم استلام رسالة من السيرفر"
      };
    } catch (e) {
      return {
        "success": false,
        "message": "⚠️ خطأ في قراءة استجابة السيرفر"
      };
    }
  } else {
    return {
      "success": false,
      "message": "❌ فشل الإضافة: ${response.statusCode} - ${response.body}"
    };
  }
}


//جلب منتج حسب المعرفid
  static Future<Map<String, dynamic>?> getProductById(int productId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/getProductById/$productId');
  final response = await DioTransport.get(url);

  print('📦 GetProductById Status: ${response.statusCode}');
  print('📦 Body: ${response.body}');

  if (response.statusCode == 200) {
    final raw = jsonDecode(response.body);

    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw as Map);

    return {
      ...map,
      'productId': map['productId'] ?? map['ProductID'] ?? map['id'],
      'productName': map['productName'] ?? map['ProductName'],
      'description': map['description'] ?? map['Description'],
      'price': map['price'] ?? map['Price'],
      'priceUSD': map['priceUSD'] ?? map['priceUsd'] ?? map['PriceUSD'],
      'sectionId': map['sectionId'] ?? map['SectionID'],
      'imageUrl1': map['imageUrl1'] ?? map['image'] ?? map['Image'],
      'imageUrl2': map['imageUrl2'] ?? map['image2'] ?? map['Image_2'],
      'imageUrl3': map['imageUrl3'] ?? map['image3'] ?? map['Image_3'],
    };
  } else {
    return null;
  }
}

//جلب عدد التفضيلات لمنتج معين
static Future<int> getFavoritesCount(int productId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/Favorite/getFavoritesCount/$productId');
  final response = await DioTransport.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['favoritesCount'] ?? 0;
  } else {
    return 0;
  }
}

//تفعيل او الغاء تفعيل منتج
static Future<Map<String, dynamic>?> toggleProductStatus(int productId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/toggleProductStatus/$productId');
  final response = await DioTransport.put(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//جلب عروض المنتجات
static Future<List<dynamic>?> getOffersWithProducts(int shopId) async {
  try {
    final dio = DioService.instance;

    final response = await dio.get(
      "/Products/getOffersWithProducts",
      queryParameters: {
        "shopId": shopId,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;

      if (data["success"] == true && data["offers"] is List) {
        return data["offers"];
      }
    }

    print("❌ فشل في تحميل العروض: ${response.data}");
    return null;
  } catch (e) {
    print("❌ خطأ في الاتصال بالسيرفر: $e");
    return null;
  }
}

//تعديل عرض او خصم 
static Future<Map<String, dynamic>?> updateOffer(
    int offerId, Map<String, dynamic> offerData) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/updateOffer/$offerId');
  final response = await DioTransport.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(offerData),
  );

  print('✏️ UpdateOffer Status: ${response.statusCode}');
  print('✏️ Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//حذف عرض او خصم
static Future<Map<String, dynamic>?> deleteOffer(int offerId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products/deleteOffer/$offerId');
  final response = await DioTransport.delete(
    url,
    headers: {'Content-Type': 'application/json'},
  );

  print('🗑️ DeleteOffer Status: ${response.statusCode}');
  print('🗑️ Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

// وبالتدريج عرض الطلبات حسب الحالة
static Future<Map<String, dynamic>?> getOrdersByStatuses(
  int shopId,
  List<String> statuses, {
  int page = 1,
  int pageSize = 6,
}) async {
  final queryParams = [
    ...statuses.map((s) => 'statuses=$s'),
    'page=$page',
    'pageSize=$pageSize',
  ].join('&');

  final url = Uri.parse(
    '${ApiConfig.baseUrl}/Orders/getByStatuses?shopId=$shopId&$queryParams',
  );

  final response = await DioTransport.get(url);

  print('📦 GetOrdersByStatuses Status: ${response.statusCode}');
  print('📦 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//تغيير حالة الطلب
static Future<Map<String, dynamic>?> updateOrderStatus(
  int shopOrderId,
  String status,
  int areaId,
) async {
  final url = Uri.parse(
    '${ApiConfig.baseUrl}/Orders/updateStatus?shopOrderId=$shopOrderId&status=$status&areaId=$areaId',
  );

  final response = await DioTransport.put(
    url,
    headers: {'Content-Type': 'application/json'},
  );

  print('🔄 UpdateOrderStatus Status: ${response.statusCode}');
  print('🔄 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

// تعديل ملاحظات المحل
static Future<Map<String, dynamic>?> updateShopNotes(int shopOrderId, String notes) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/Orders/updateNotes');
  final response = await DioTransport.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'shopOrderId': shopOrderId,
      'notes': notes,
    }),
  );

  print('📝 UpdateShopNotes Status: ${response.statusCode}');
  print('📝 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//عرض تفاصيل الطلب
static Future<Map<String, dynamic>?> getOrderDetails(int shopOrderId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/Orders/details/$shopOrderId');
  final response = await DioTransport.get(url);

  print('🔍 GetOrderDetails Status: ${response.statusCode}');
  print('🔍 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

//عرض سلايدر
static Future<Map<String, dynamic>?> getActiveSlidersByShop(
  int shopId, {
  int page = 1,
  int pageSize = 5,
}) async {
  try {
    final dio = DioService.instance;

    final response = await dio.get(
      "/Sliders/getActiveSlidersByShop/$shopId",
      queryParameters: {
        "page": page,
        "pageSize": pageSize,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;

      if (data["success"] == true) {
        return data; // يحتوي sliders + totalSliders + page + pageSize
      }
    }

    print("❌ فشل في تحميل السلايدرات: ${response.data}");
    return null;
  } catch (e) {
    print("❌ خطأ في الاتصال بالسيرفر: $e");
    return null;
  }
}

//تعديل سلايدر
static Future<bool> updateSlider(
  int sliderId,
  Map<String, dynamic> data, {
  File? imageFile,
}) async {
  try {
    final dio = DioService.instance;

    // 🟢 تجهيز FormData
    FormData formData = FormData.fromMap({
      "title": data["title"],
      "targetType": data["targetType"],
      "targetId": data["targetId"],
      "startDate": data["startDate"],
      "endDate": data["endDate"],

      // 🟢 إرسال الصورة كملف إذا تم اختيار صورة جديدة
      if (imageFile != null)
        "imageFile": await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
    });

    final response = await dio.put(
      "/Sliders/updateSlider/$sliderId",
      data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );

    print("PUT Status: ${response.statusCode}");
    print("PUT Body: ${response.data}");

    if (response.statusCode == 200 &&
        response.data["success"] == true) {
      return true;
    }

    return false;
  } catch (e) {
    print("❌ Slider Update Error: $e");
    return false;
  }
}

//اضافة وظيفة جديدة
static Future<Map<String, dynamic>?> addJobVacancy(Map<String, dynamic> body) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/jobvacancies/add');

    final response = await DioTransport.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      // السيرفر أرجع 2xx لكن success=false — نُرجع الرد كاملاً ليُعرض الخطأ
      return data;
    }
    // محاولة استخراج رسالة الخطأ من السيرفر
    try {
      return jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {}
    return null;
  } catch (e) {
    debugPrint('[addJobVacancy] error: $e');
    return null;
  }
}

//تعديل وظيفة
static Future<bool> updateJobVacancy(Map<String, dynamic> body) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/jobvacancies/update');

    final response = await DioTransport.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  } catch (e) {
    debugPrint('[updateJobVacancy] error: $e');
    return false;
  }
}

//حذف وظيفة
static Future<bool> deleteJobVacancy(int vacancyId) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/jobvacancies/delete');

    final response = await DioTransport.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"vacancyId": vacancyId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  } catch (e) {
    debugPrint('[deleteJobVacancy] error: $e');
    return false;
  }
}

//جلب الوطائف كلها حسب معرف المحل
static Future<List<dynamic>?> getJobVacancies(int shopId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/jobvacancies/list/$shopId');

  final response = await DioTransport.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['vacancies'];
    }
  }
  return null;
}

// 🔍 البحث عن المنتجات حسب الاسم داخل المحل 
static Future<List<dynamic>?> searchProducts({
  required int shopId,
  required String query,
  int page = 1,
  int pageSize = 20,
}) async {
  final url = Uri.parse(
    '${ApiConfig.baseUrl}/products/search'
    '?shopId=$shopId&query=$query&page=$page&pageSize=$pageSize',
  );

  final response = await DioTransport.get(url);

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    // نرجع فقط قائمة المنتجات مثل أسلوبك
    return decoded["data"] as List<dynamic>;
  } else {
    return null;
  }
}

//جعل جميع الاشعارات كمقروء
static Future<Map<String, dynamic>> markAllNotificationsAsRead(
    String userType, int userId) async {

  final url = Uri.parse(
      '${ApiConfig.baseUrl}/Notifications/notifications/mark-all-read/$userType/$userId');

  final response = await DioTransport.post(
    url,
    headers: {"Content-Type": "application/json"},
  );

  try {
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  } catch (e) {
    return {
      "success": false,
      "message": "خطأ في الاتصال بالسيرفر أو استجابة غير صالحة"
    };
  }
}

//جلب المنتجات بالتدريج حسب التصنيفات
static Future<Map<String, dynamic>?> getProductsBySectionPagedIneffective(
    int sectionId, int page, int pageSize) async {
  final url = Uri.parse(
      '${ApiConfig.baseUrl}/products/getProductsBySectionPagedIneffective/$sectionId?page=$page&pageSize=$pageSize');

  final response = await DioTransport.get(url);
print("🌍 URL = $url");


  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}


//تعديل كمية عناصر الطلب
static Future<Map<String, dynamic>?> updateShopOrderItemQuantity(
    int shopOrderItemId,
    int newQuantity,
  ) async {

  final url = Uri.parse(
    '${ApiConfig.baseUrl}/Orders/updateShopOrderItemQuantity',
  );

  final body = jsonEncode({
    "ShopOrderItemID": shopOrderItemId,
    "NewQuantity": newQuantity,
  });

  final response = await DioTransport.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  print('🔄 UpdateShopOrderItemQuantity Status: ${response.statusCode}');
  print('🔄 Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

}


