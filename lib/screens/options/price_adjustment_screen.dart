import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../snackBar/snackbar.dart';
import '../../core/app_events.dart';
import '../../widgets/loading_dots_widget.dart';

class PriceAdjustmentScreen extends StatefulWidget {
  const PriceAdjustmentScreen({super.key});

  @override
  State<PriceAdjustmentScreen> createState() => _PriceAdjustmentScreenState();
}

class _PriceAdjustmentScreenState extends State<PriceAdjustmentScreen> {
  bool showAll = true; // ✅ افتراضيًا "الكل"
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List sections = []; // 🗂️ الأقسام مع المنتجات
  final Map<int, TextEditingController> priceControllers = {};
  bool isLoading = true;
  bool isSaving = false;

  String _normalizeDigits(String input) {
    const arabicIndic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    const easternArabicIndic = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];

    var out = input.trim();
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabicIndic[i], '$i');
      out = out.replaceAll(easternArabicIndic[i], '$i');
    }

    return out
        .replaceAll('٫', '.')
        .replaceAll('٬', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');
  }

  int? _parsePriceInput(String raw) {
    final normalized = _normalizeDigits(raw);
    if (normalized.isEmpty) return null;

    final asInt = int.tryParse(normalized);
    if (asInt != null) return asInt;

    final asDouble = double.tryParse(normalized);
    if (asDouble == null) return null;

    return asDouble.toInt();
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildPriceAdjustmentShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: showAll ? 10 : 14,
        itemBuilder: (context, index) {
          if (!showAll && index % 5 == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(child: _shimmerBox(width: 150, height: 22, radius: 10)),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: _shimmerBox(width: double.infinity, height: 23, radius: 10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: Column(
                    children: [
                      _shimmerBox(width: 60, height: 25, radius: 6),
                      const SizedBox(height: 4),
                      _shimmerBox(width: 60, height: 7, radius: 1),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;

    setState(() => isLoading = true);

    if (showAll) {
      // ✅ جلب جميع المنتجات
      final result = await ApiService.getProductsByShop(shopId);
      if (result != null) {
        setState(() {
          allProducts = result;
          filteredProducts = result;
          for (var p in allProducts) {
            priceControllers[p['productId']] =
                TextEditingController(text: p['price'].toString());
          }
          isLoading = false;
        });
      }
    } else {
      // 🗂️ جلب الأقسام مع المنتجات
      final result = await ApiService.getSectionsWithProductsLite(shopId);
      if (result != null) {
        setState(() {
          sections = result['sections'];
          for (var s in sections) {
            for (var p in s['products']) {
              priceControllers[p['productId']] =
                  TextEditingController(text: p['price'].toString());
            }
          }
          isLoading = false;
        });
      }
    }
  }

  void _filterProducts(String keyword) {
    if (showAll) {
      final results = allProducts.where((p) {
        final name = p['productName'].toString().toLowerCase();
        final price = p['price'].toString();
        final search = keyword.toLowerCase();
        return name.contains(search) || price.contains(search);
      }).toList();

      setState(() {
        filteredProducts = results;
      });
    } else {
      // 🗂️ فلترة حسب التصنيف
      final filteredSections = sections.map((s) {
        final products = (s['products'] as List).where((p) {
          final name = p['productName'].toString().toLowerCase();
          final price = p['price'].toString();
          final search = keyword.toLowerCase();
          return name.contains(search) || price.contains(search);
        }).toList();

        return {
          'sectionId': s['sectionId'],
          'sectionName': s['sectionName'],
          'products': products,
        };
      }).toList();

      setState(() {
        sections = filteredSections;
      });
    }
  }

  /// ✨ دالة الحفظ
  Future<void> _saveChanges() async {
  if (isSaving) return; // منع الضغط المتكرر

  setState(() {
    isSaving = true; // بدء التحميل
  });

  bool updated = false;
  bool hasInvalidInput = false;
  int changedCount = 0;

  Future<void> processItem(Map<String, dynamic> p) async {
    final productId = p['productId'];
    final controller = priceControllers[productId];
    if (controller == null) return;

    final parsedPrice = _parsePriceInput(controller.text);
    if (parsedPrice == null) {
      hasInvalidInput = true;
      return;
    }

    final oldPrice = (p['price'] as num).toInt();
    if (parsedPrice != oldPrice) {
      changedCount++;
      final res = await ApiService.updateProductPrice(productId, parsedPrice);
      if (res != null && res['success'] == true) {
        p['price'] = parsedPrice;
        updated = true;
      }
    }
  }

  if (showAll) {
    for (var p in allProducts) {
      await processItem(p);
    }
  } else {
    for (var s in sections) {
      for (var p in s['products']) {
        await processItem(p);
      }
    }
  }

  if (updated) {
    snackBar(context, "تم تعديل الاسعار بنجاح");
   // AppEvents().emit("refresh_home");
    AppEvents().emit("refresh_sections");
    AppEvents().emit("refresh_offers");
  }

  setState(() {
    isSaving = false; // انتهاء التحميل
  });

  if (hasInvalidInput) {
    snackBar(context, "يوجد سعر غير صالح. أدخل أرقام فقط");
    return;
  }

  if (changedCount == 0) {
    snackBar(context, "لا توجد تعديلات للحفظ");
    return;
  }

  if (!updated) {
    snackBar(context, "لم يتم الحفظ، تحقق من الاتصال");
    return;
  }

  Navigator.pop(context, true); // رجوع فقط بعد حفظ ناجح
}


  @override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    // ❌ بدون AppBar

    body: Column(
      children: [
        // مسافة 5% من ارتفاع الشاشة
        SizedBox(height: screenHeight * 0.05),

        // عنوان في المنتصف
        const Center(
          child: Text(
            "تعديل الأسعار",
            style: TextStyle(
              fontSize: 20,
              //fontFamily: "Tajawal",
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ✅ خيارات الكل / حسب التصنيف (Radio بدلاً من Checkbox)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           
 const Text("حسب التصنيف"),
            Radio<bool>(
              value: false,
              groupValue: showAll,
              activeColor: Color(0xFF5A9BD5),
              onChanged: (val) {
                setState(() {
                  showAll = false;
                });
                _loadProducts();
              },
            ),
           
             const Text("الكل"),
             Radio<bool>(
              value: true,
              groupValue: showAll,
              activeColor: Color(0xFF5A9BD5),
              onChanged: (val) {
                setState(() {
                  showAll = true;
                });
                _loadProducts();
              },
            ),
           
          ],
        ),

        // 🔎 مربع البحث
     Padding(
  padding: const EdgeInsets.all(8.0),
  child: Directionality(
    textDirection: TextDirection.rtl,
    child: TextField(
      onChanged: _filterProducts,
      decoration: const InputDecoration(
        labelText: "بحث",
        border: OutlineInputBorder(),
        prefixIcon: Padding(
          padding: EdgeInsets.only(right: 8),   // 👈 مسافة من اليمين
          child: Icon(Icons.search),
        ),
      ),
    ),
  ),
),

        // 📋 عرض المنتجات أو الأقسام
        Expanded(
          child: isLoading
              ? _buildPriceAdjustmentShimmer()
              : showAll
                  // ✅ حالة "الكل"
                  ? ListView.builder(
  itemCount: filteredProducts.length,
  itemBuilder: (context, index) {
    final p = filteredProducts[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          // 👈 الاسم على اليسار + مسافة من اليسار
          Expanded(
  child: Padding(
    padding: const EdgeInsets.only(left: 30),
    child: Text(
      p['productName'],
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 18,
        fontFamily: "Tajawal",       // حسب الخط المستخدم عندك
      ),
    ),
  ),
),

          // 👈 السعر على اليمين + مسافة من اليمين
         Padding(
  padding: const EdgeInsets.only(right: 30),
  child: SizedBox(
    width: 60,
    child: TextField(
      controller: priceControllers[p['productId']],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.left,
      style: const TextStyle(
        color: Color(0xFF5A9BD5),   // ← لون النص الأزرق
        fontSize: 16,         // اختياري
        fontWeight: FontWeight.w600, // اختياري
      ),
      decoration: const InputDecoration(
        border: UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 0),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 2),
        ),
      ),
    ),
  ),
),
        ],
      ),
    );
  },
)
                  // 🗂️ حالة "حسب التصنيف"
                  : ListView.builder(
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        final products = section['products'] as List;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🏷️ اسم القسم
                           Padding(
  padding: const EdgeInsets.all(8.0),
  child: Center(
    child: Text(
      section['sectionName'],
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

                            // 📋 منتجات القسم
                          ...products.map((p) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    child: Row(
      children: [
        // 👈 الاسم على اليسار + مسافة من اليسار
        Expanded(
          child: Padding(
    padding: const EdgeInsets.only(left: 30),
    child: Text(
      p['productName'],
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 18,
        fontFamily: "Tajawal",       // حسب الخط المستخدم عندك
      ),
    ),
  ),
        ),

        // 👈 السعر على اليمين + مسافة من اليمين
       Padding(
  padding: const EdgeInsets.only(right: 30),
  child: SizedBox(
    width: 60,
    child: TextField(
  controller: priceControllers[p['productId']],
  keyboardType: TextInputType.number,
  textAlign: TextAlign.left,
  textAlignVertical: TextAlignVertical.center, // محاذاة عمودية مثالية
  style: const TextStyle(
    color: Color(0xFF5A9BD5),   // لون النص الأزرق
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,                // يجعل النص على السطر تمامًا
  ),
  decoration: const InputDecoration(
    isDense: true, // يقلل الارتفاع الافتراضي
    contentPadding: EdgeInsets.symmetric(vertical: 8), // ضبط الارتفاع
    border: UnderlineInputBorder(),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 0),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 2),
    ),
  ),
),
  ),
),
      ],
    ),
  );
}).toList(),
                          ],
                        );
                      },
                    ),
        ),
      ],
    ),

    // ✅ زر التأكيد
   bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(12.0),
  child: SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton(
      onPressed: (isSaving || isLoading) ? null : _saveChanges,
      child: isSaving
          ? const LoadingDotsWidget()
          : const Text(
              "تأكيد",
              style: TextStyle(
                fontFamily: "Tajawal",
                fontSize: 16,
              ),
            ),
    ),
  ),
),
  );
}
}
