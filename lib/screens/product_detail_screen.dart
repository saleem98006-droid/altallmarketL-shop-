
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import 'snackBar/snackbar.dart';
import '../core/app_events.dart';
import '../providers/router_provider.dart';
import 'dart:async';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic>? offer;

  const ProductDetailScreen({super.key, required this.product, this.offer});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Map<String, dynamic> product;
  Map<String, dynamic>? offer;
  bool _loading = false;
  bool showMenuCard = false;
  int favoriteCount = 0;
late StreamSubscription<String> _eventSubscription;

 List<String> imageUrls = [];       // ← الآن نخزن الروابط فقط
int currentImageIndex = 0;
  @override
  void initState() {
    super.initState();

    product = _normalizeProduct(widget.product);
    offer = widget.offer;

    _ensureFullProduct();
    _loadFavoriteCount();

    _prepareImages();   // ← تجهيز الصور مرة واحدة فقط

    
  // ⭐ الاستماع لحدث تحديث المنتج
  _eventSubscription = AppEvents().stream.listen((event) {
    if (!mounted) return;

    if (event == "refresh_product_detail") {
      _refreshProductDetail();
    }
  });

  }
  Future<void> _refreshProductDetail() async {
  final id = product['productId'];
  if (id == null) return;

  final full = await ApiService.getProductById(id);

  if (full != null) {
    setState(() {
      product = _normalizeProduct(full);
      _prepareImages();   // ← إعادة تجهيز الصور مع كسر الكاش
    });
  }
}
@override
void dispose() {
  _eventSubscription.cancel();
  super.dispose();
}
  Future<void> _loadFavoriteCount() async {
    final id = product['productId'];
    if (id != null) {
      final count = await ApiService.getFavoritesCount(id);
      setState(() {
        favoriteCount = count;
      });
    }
  }

  

 

  /// 🔥 تجهيز الصور مرة واحدة فقط بدون إعادة بناء
 void _prepareImages() {
  final rawImages = [
    product['imageUrl1'],
    product['imageUrl2'],
    product['imageUrl3'],
  ];

  imageUrls = [];

  for (var img in rawImages) {
    if (img is String && img.trim().isNotEmpty) {
     final cacheBusted = "${img.trim()}?v=${DateTime.now().millisecondsSinceEpoch}";
imageUrls.add(cacheBusted);
    }
  }

  if (mounted) setState(() {});
}

  Map<String, dynamic> _normalizeProduct(Map<String, dynamic> p) {
    final normalized = Map<String, dynamic>.from(p);

    normalized['productId'] = p['productId'] ?? p['ProductID'] ?? p['id'];
    normalized['productName'] = p['productName'] ?? p['ProductName'];
    normalized['price'] = p['price'] ?? p['Price'];
    normalized['description'] = p['description'] ?? p['Description'] ?? '';
    normalized['isActive'] = p['isActive'] ?? p['IsActive'] ?? true;

    /*normalized['image'] = p['image'] ?? p['Image'];
    normalized['image2'] = p['image2'] ?? p['Image_2'];
    normalized['image3'] = p['image3'] ?? p['Image_3'];*/
    normalized['imageUrl1'] = p['imageUrl1'] ?? p['image'] ?? p['Image'];
normalized['imageUrl2'] = p['imageUrl2'] ?? p['image2'] ?? p['Image_2'];
normalized['imageUrl3'] = p['imageUrl3'] ?? p['image3'] ?? p['Image_3'];

    return normalized;
  }

  Future<void> _ensureFullProduct() async {
    final id = product['productId'];
    final needsRefresh =
        (product['isActive'] == null || product['price'] == null);

    if (id != null && needsRefresh) {
      setState(() => _loading = true);
      final full = await ApiService.getProductById(id);
      if (full != null) {
        setState(() => product = _normalizeProduct(full));
      }
      setState(() => _loading = false);
    }
  }

 

  String _getOfferLabel(Map<String, dynamic> offer) {
  final type = offer['offerType']?.toString() ?? "";

  // حساب السعر والخصم من داخل الـ State
  final double price =
      (product['price'] is num) ? (product['price'] as num).toDouble() : 0.0;

  final double discountValue =
      (offer['discountValue'] is num) ? (offer['discountValue'] as num).toDouble() : 0.0;

  final double finalPrice = price - discountValue;

  // -----------------------------
  // 1) خصم مباشر DirectDiscount
  // -----------------------------
  if (type == "DirectDiscount") {
    if (discountValue > 0 && price > 0) {
      final percent = ((price - finalPrice) / price * 100).round();
      return "خصم مباشر $percent% (${discountValue.toInt()} ل.س)";
    }
    return "خصم مباشر";
  }

  // -----------------------------
  // 2) Buy X Get Y
  // -----------------------------
  final buyQty = (offer['buyQuantity'] is num)
      ? (offer['buyQuantity'] as num).toInt()
      : null;

  final getQty = (offer['getQuantity'] is num)
      ? (offer['getQuantity'] as num).toInt()
      : null;

  final freeName = offer['freeProductName']?.toString() ?? "";

  if (type == "BuyXGetY" && buyQty != null && getQty != null) {
    if (freeName.isNotEmpty) {
      return "اشترِ $buyQty واحصل على $getQty × $freeName";
    }
    return "اشترِ $buyQty واحصل على $getQty مجاناً";
  }

  // -----------------------------
  // 3) FreeItem
  // -----------------------------
  if (type == "FreeItem" && buyQty != null) {
    if (freeName.isNotEmpty) {
      return "اشترِ $buyQty واحصل على $freeName مجاناً";
    }
    return "اشترِ $buyQty واحصل على منتج مجاني";
  }

  // -----------------------------
  // 4) label إن وجد
  // -----------------------------
  if (offer['label'] != null && offer['label'].toString().isNotEmpty) {
    return offer['label'].toString();
  }

  return "عرض مميز";
}

  @override
Widget build(BuildContext context) {
  final double price =
      (product['price'] is num) ? (product['price'] as num).toDouble() : 0.0;
  final double discountValue =
      (offer != null && offer!['discountValue'] is num)
          ? (offer!['discountValue'] as num).toDouble()
          : 0.0;
  final double finalPrice = price - discountValue;

  final screenHeight = MediaQuery.of(context).size.height;

  return Directionality(
    textDirection: TextDirection.rtl,
   child: Scaffold(
  backgroundColor: product['isActive'] == true
      ? Colors.white
      : Colors.grey.shade400,   // ← خلفية رمادية عند عدم التفعيل
  body: Stack(
        children: [

          // ============================
          // المحتوى الأساسي
          // ============================
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // 🖼️ الصور خارج السكرول
                      GestureDetector(
                        onTap: () {
                          if (imageUrls.isEmpty) return;


                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                backgroundColor: Colors.black,
                                insetPadding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Stack(
                                  children: [
                                    PageView.builder(
                                      controller: PageController(
                                          initialPage: currentImageIndex),
                                     itemCount: imageUrls.length,
itemBuilder: (context, index) {
  return InteractiveViewer(
    child: CachedNetworkImage(
      imageUrl: ApiConfig.baseUrl + imageUrls[index],
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.broken_image,
        color: Colors.white,
        size: 60,
      ),
    ),
  );
},
                                    ),

                                    Positioned(
                                      top: 30,
                                      right: 20,
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 30),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: SizedBox(
                            height: screenHeight * 0.30,
                            width: double.infinity,
                           child: imageUrls.isNotEmpty
    ? PageView.builder(
        itemCount: imageUrls.length,
        onPageChanged: (i) {
          setState(() => currentImageIndex = i);
        },
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: ApiConfig.baseUrl + imageUrls[index],
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image,
                  size: 80, color: Colors.grey),
            ),
          );
        },
      )
    : const Center(
        child: Icon(Icons.image,
            size: 120, color: Colors.grey),
      ),
                          ),
                        ),
                      ),

                      // باقي الصفحة داخل Scroll
                      Expanded(
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),

                              // 🔘 زر الثلاث نقاط بدل الأزرار
                              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

    // 🏷️ اسم المنتج على اليمين
    Expanded(
      child: Text(
        product['productName'] ?? 'اسم المنتج',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),

    // ⋮ الثلاث نقاط على اليسار
    IconButton(
      icon: const Icon(Icons.more_vert, size: 30),
      onPressed: () {
        setState(() {
          showMenuCard = !showMenuCard;
        });
      },
    ),
  ],
),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  const Icon(Icons.favorite,
                                      color: Colors.pink),
                                  const SizedBox(width: 6),
                                  Text(
                                    "$favoriteCount",
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // 💰 السعر
                              _buildPriceSection(price, finalPrice),

                              const SizedBox(height: 16),

                              // 📝 الوصف
                              Text(
                                (product['description']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true)
                                    ? product['description']
                                    : "لا يوجد وصف",
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.justify,
                              ),

                              const SizedBox(height: 24),

                              if (offer != null) _buildOfferSection(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // ============================
          // البطاقة العائمة (ثلاث خيارات)
          // ============================
          if (showMenuCard)
            Positioned(
               top: MediaQuery.of(context).size.height * 0.40,   // 12% من ارتفاع الشاشة
  left: MediaQuery.of(context).size.width * 0.05,   // 5% من عرض الشاشة

              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FCFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Directionality(
  textDirection: TextDirection.rtl,   // ← مهم جداً
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // 🔵 تفعيل / إلغاء تفعيل
     InkWell(
  onTap: () async {
    setState(() => showMenuCard = false);

    final id = product['productId'];
    if (id == null) return;

    print("🔵 BEFORE TOGGLE — isActive: ${product['isActive']}");

    final response = await ApiService.toggleProductStatus(id);

    print("🟣 API RESPONSE: $response");

    if (response != null && response['success'] == true) {
      setState(() {
        product['isActive'] = response['isActive'];
      });

      print("🟢 AFTER TOGGLE — isActive: ${product['isActive']}");

      AppEvents().emit("refresh_sections");
      AppEvents().emit("refresh_section_products");

      snackBar(context, response['message'] ?? "تم تغيير الحالة");
    }
  },
  child: Row(
    children: [
      Image.asset(
        product['isActive'] == true
            ? "assets/images/closed_eye.png"
            : "assets/images/eye.png",
        width: 22,
        height: 22,
      ),
      const SizedBox(width: 8),
      Text(
        product['isActive'] == true ? "إلغاء التفعيل" : "تفعيل",
        style: const TextStyle(fontFamily: "Tajawal", fontSize: 16),
      ),
    ],
  ),
),
      const SizedBox(height: 10),

      // ✏️ تعديل
      InkWell(
        onTap: () async {
          setState(() => showMenuCard = false);

          final result = await context.push(
            AppRoutes.editProduct,
            extra: {
              'product': product,
              'offer': offer,
            },
          );

          if (result == true) {
            Navigator.pop(context, true);
          }
        },
        child: Row(
          children:  [
            Image.asset(
  "assets/images/update.png",
  color:Colors.black,
  width: 22,
  height: 22,
),
            SizedBox(width: 8),
            Text("تعديل", style: TextStyle(fontFamily: "Tajawal",fontSize:16)),
          ],
        ),
      ),

      const SizedBox(height: 10),

      // 🗑️ حذف
      InkWell(
        onTap: () async {
          setState(() => showMenuCard = false);

          final id = product['productId'];
          if (id == null) return;

          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => _deleteDialog(context),
          );

          if (confirm == true) {
            final response = await ApiService.deleteProduct(id);
            if (response != null && response['success'] == true) {
               AppEvents().emit("refresh_home");
             AppEvents().emit("refresh_section_products");
              Navigator.pop(context, true);
             
            }
          }
        },
        child: Row(
          children:  [
           Image.asset(
  "assets/images/trash.png",
  width: 22,
  height: 22,
),
            SizedBox(width: 8),
            Text("حذف", style: TextStyle(fontFamily: "Tajawal",fontSize:16)),
          ],
        ),
      ),

    ],
  ),
),
                ),
              ),
            ),

        ],
      ),
    ),
  );
}

  Widget _deleteDialog(BuildContext context) {
  return AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
    ),
    content: const Text(
      "هل أنت متأكد أنك تريد حذف هذا المنتج؟",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    actions: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                "إلغاء",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                "حذف",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildPriceSection(double price, double finalPrice) {
  if (offer != null && offer!['offerType'] == "DirectDiscount") {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${price.toInt()} ل.س",
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          "${finalPrice.toInt()} ل.س",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  return Text(
    "${price.toInt()} ل.س",
    style: const TextStyle(fontSize: 18, color: Color(0xFF5A9BD5)),
  );
}
Widget _buildOfferSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      const Text(
        "تفاصيل العرض",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        _getOfferLabel(offer!),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.blue,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
}