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
  final Map<int, TextEditingController> priceUsdControllers = {};
  bool _isDollarEnabled = false;
  String _selectedCurrency = 'SYP'; // SYP | USD
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

  double? _parseNumberInput(String raw) {
    final normalized = _normalizeDigits(raw);
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _initialNumberText(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      return value == value.toInt() ? value.toInt().toString() : value.toString();
    }
    return value.toString();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _fieldHint(bool isUsd) => isUsd ? '\$' : 'ل.س';

  Widget _priceInputField({
    required TextEditingController controller,
    required bool isUsd,
  }) {
    return SizedBox(
      width: 66,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Color(0xFF5A9BD5),
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          hintText: _fieldHint(isUsd),
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: const UnderlineInputBorder(),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 0),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceEditors(Map<String, dynamic> product) {
    final productId = product['productId'] as int;
    final sypController =
        priceControllers[productId] ?? TextEditingController();
    final usdController =
        priceUsdControllers[productId] ?? TextEditingController();

    final useUsd = _isDollarEnabled && _selectedCurrency == 'USD';
    final controller = useUsd ? usdController : sypController;

    return Padding(
      padding: const EdgeInsets.only(right: 30),
      child: _priceInputField(controller: controller, isUsd: useUsd),
    );
  }

  Widget _buildCurrencyFilter() {
    if (!_isDollarEnabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("دولار"),
          Radio<String>(
            value: 'USD',
            groupValue: _selectedCurrency,
            activeColor: const Color(0xFF5A9BD5),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedCurrency = val;
              });
            },
          ),
          const Text("سوري"),
          Radio<String>(
            value: 'SYP',
            groupValue: _selectedCurrency,
            activeColor: const Color(0xFF5A9BD5),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedCurrency = val;
              });
            },
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    for (final c in priceControllers.values) {
      c.dispose();
    }
    for (final c in priceUsdControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;

    var isDollarEnabled = prefs.getBool('isDollarEnabled') ?? false;
    if (shopId > 0) {
      final shopData = await ApiService.getShopById(shopId);
      if (shopData != null &&
          (shopData.containsKey('isDollarEnabled') ||
              shopData.containsKey('IsDollarEnabled'))) {
        final raw = shopData['isDollarEnabled'] ?? shopData['IsDollarEnabled'];
        isDollarEnabled = raw == true ||
            raw.toString().trim().toLowerCase() == 'true' ||
            raw.toString().trim() == '1';
        await prefs.setBool('isDollarEnabled', isDollarEnabled);
      }
    }

    setState(() => isLoading = true);

    if (showAll) {
      // ✅ جلب جميع المنتجات
      final result = await ApiService.getProductsByShop(shopId);
      if (result != null) {
        setState(() {
          _isDollarEnabled = isDollarEnabled;
          allProducts = result;
          filteredProducts = result;
          for (var p in allProducts) {
            priceControllers[p['productId']] =
                TextEditingController(text: _initialNumberText(p['price']));
            priceUsdControllers[p['productId']] = TextEditingController(
              text: _initialNumberText(p['priceUSD']),
            );
          }
          if (!_isDollarEnabled) {
            _selectedCurrency = 'SYP';
          }
          isLoading = false;
        });
      }
    } else {
      // 🗂️ جلب الأقسام مع المنتجات
      final result = await ApiService.getSectionsWithProductsLite(shopId);
      if (result != null) {
        setState(() {
          _isDollarEnabled = isDollarEnabled;
          sections = result['sections'];
          for (var s in sections) {
            for (var p in s['products']) {
              priceControllers[p['productId']] =
                  TextEditingController(text: _initialNumberText(p['price']));
              priceUsdControllers[p['productId']] = TextEditingController(
                text: _initialNumberText(p['priceUSD']),
              );
            }
          }
          if (!_isDollarEnabled) {
            _selectedCurrency = 'SYP';
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
    final sypController = priceControllers[productId];
    final usdController = priceUsdControllers[productId];
    if (sypController == null) return;

    final bool editUsd = _isDollarEnabled && _selectedCurrency == 'USD';

    double? parsedPrice;
    if (!editUsd) {
      parsedPrice = _parseNumberInput(sypController.text);
      if (parsedPrice == null || parsedPrice <= 0) {
        hasInvalidInput = true;
        return;
      }
    }

    final oldUsd = _toDouble(p['priceUSD']);
    final oldPrice = _toDouble(p['price']) ?? 0;

    double? effectiveUsd = oldUsd;
    if (editUsd) {
      final typedUsd = _parseNumberInput(usdController?.text ?? '');
      if (typedUsd == null || typedUsd <= 0) {
        hasInvalidInput = true;
        return;
      }
      effectiveUsd = typedUsd;
    } else if (!_isDollarEnabled) {
      effectiveUsd = null;
    }

    final effectiveSyp = parsedPrice ?? oldPrice;

    final isSypChanged = !editUsd && (effectiveSyp != oldPrice);
    final isUsdChanged = _isDollarEnabled && (effectiveUsd != oldUsd);

    if (isSypChanged || isUsdChanged) {
      changedCount++;
      final res = await ApiService.updateProductPrice(
        productId,
        price: editUsd ? null : effectiveSyp,
        priceUSD: _isDollarEnabled ? effectiveUsd : null,
      );
      if (res != null && res['success'] == true) {
        p['price'] = res['newPrice'] ?? effectiveSyp;
        p['priceUSD'] = _isDollarEnabled ? (res['newPriceUSD'] ?? effectiveUsd) : null;

        priceControllers[productId]?.text =
            _initialNumberText(p['price']);
        if (_isDollarEnabled) {
          priceUsdControllers[productId]?.text =
              _initialNumberText(p['priceUSD']);
        }

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

        _buildCurrencyFilter(),

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
         _buildPriceEditors(p),
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
       _buildPriceEditors(p),
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
