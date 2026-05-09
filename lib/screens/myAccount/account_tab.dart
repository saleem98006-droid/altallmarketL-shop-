import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../snackBar/snackbar.dart';
import '../../providers/router_provider.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  Map<String, dynamic>? shopData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt("shopId");

    if (shopId == null) {
      setState(() {
        isLoading = false;
      });
      print("❌ لا يوجد shopId في التخزين");
      return;
    }

    final result = await ApiService.getShopById(shopId);

    if (!mounted) return;

    setState(() {
      shopData = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (shopData == null) {
      return const Center(child: Text("❌ فشل في جلب بيانات المحل"));
    }

    List<dynamic> phones = shopData!['phoneNumbers'] ?? [];
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 🔵 الصورة الكبيرة أعلى الشاشة
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: SizedBox(
              height: screenHeight * 0.2,
              width: double.infinity,
              child: (shopData!['shopImageUrl'] != null)
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.baseUrl + shopData!['shopImageUrl'] +
    "?v=${DateTime.now().millisecondsSinceEpoch}",
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[300],
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.store,
                            size: 80, color: Colors.blue),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.store,
                          size: 80, color: Colors.blue),
                    ),
            ),
          ),

          // 🔵 محتوى الصفحة
          ListView(
            padding:
                EdgeInsets.only(top: screenHeight * 0.15, left: 16, right: 16),
            children: [
              // 🖼️ الصورة الدائرية + اسم المحل
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // الصورة الدائرية
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: (shopData!['shopImage2Url'] != null)
                          ? CachedNetworkImageProvider(
  ApiConfig.baseUrl + shopData!['shopImage2Url'] +
      "?v=${DateTime.now().millisecondsSinceEpoch}",
)
                          : null,
                      child: (shopData!['shopImage2Url'] == null)
                          ? const Icon(Icons.store_mall_directory,
                              size: 50, color: Colors.blue)
                          : null,
                    ),
                  ),

                  // الاسم
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6, top: 50),
                      child: Text(
                        shopData!['shopName'] ?? "اسم المحل",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Tajawal",
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 📞 أرقام الهاتف
              if (phones.isNotEmpty)
                ...phones.map((phone) => Column(
                      children: [
                        InkWell(
                          onLongPress: () {
                            HapticFeedback.vibrate();
                            Clipboard.setData(
                                ClipboardData(text: phone.toString()));
                            snackBar(context, "تم النسخ");
                          },
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  phone.toString(),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Image.asset("assets/images/phone.png",
                                  width: 28, height: 28),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    )),

              // 📍 العنوان
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      shopData!['address'] ?? "لا يوجد عنوان",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 18, fontFamily: "Tajawal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    "assets/images/location.png",
                    width: 28,
                    height: 28,
                    color: Colors.black,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 📝 الوصف
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      shopData!['detailes'] ?? "لا يوجد تفاصيل",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 18, fontFamily: "Tajawal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset("assets/images/describtion.png",
                      width: 28, height: 28),
                ],
              ),
            ],
          ),
        ],
      ),

      // زر التعديل
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: SizedBox(
          width: 70,
          height: 70,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            elevation: 0,
            highlightElevation: 0,
            onPressed: () async {
              final updated = await context.push<bool>(AppRoutes.updateAccount);
              if (updated == true) {
                _loadShop();
              }
            },
            shape: const CircleBorder(
              side: BorderSide(color: Color(0xFF5A9BD5), width: 3),
            ),
            child: Image.asset(
              'assets/images/update.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}