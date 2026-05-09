import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_data_provider.dart';
import 'slider_section.dart';
import 'offer_card.dart';
import 'product_card.dart';
import 'offer_card_vertical.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final HomeDataProvider provider = HomeDataProvider();

  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

 Future<void> _load() async {
  setState(() => isLoading = true);

  final prefs = await SharedPreferences.getInstance();
  final shopId = prefs.getInt('shopId') ?? 0;

  if (shopId == 0) {
    setState(() => isLoading = false);
    return;
  }

  // 🔥 كسر الكاش الصحيح
  provider.clearCache();

  // 🔥 إعادة التحميل من API
  await provider.loadSections(shopId);

  setState(() => isLoading = false);
}

 @override
Widget build(BuildContext context) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _load,          // 🔥 التحديث بالسحب
          color: Color(0xFF5A9BD5),        // لون دائرة التحميل
          child: _buildContent(),    // المحتوى كما هو
        ),
      ),

      // 🔍 صندوق البحث
      Positioned(
  
          top: -22,
          left: 20,
          right: 20,
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(30),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: "ابحث عن منتج...",
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    "assets/images/search.png",
                    height: 20,
                    width: 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🧱 المحتوى الرئيسي
  Widget _buildContent() {
    if (isLoading) {
      return ListView(
        padding: const EdgeInsets.only(top: 60, right: 12, left: 12),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (provider.sections == null ||
    provider.sections!['sections'] == null ||
    (provider.sections!['sections'] as List).isEmpty) {
  return ListView(
    padding: const EdgeInsets.only(top: 60, right: 12, left: 12),
    children: const [
      SizedBox(height: 200),
      Center(child: Text("لا يوجد بيانات")),
    ],
  );
}


    final sliders = provider.sliders ?? [];
    final sliderImages = provider.sliderImages ?? [];
    final offers = provider.offers ?? [];
    final sections = List<dynamic>.from(provider.sections!['sections']);

    final query = searchQuery.toLowerCase();
    final queryNum = double.tryParse(searchQuery.trim());

    // 🟥 خصومات DirectDiscount
    final discountOffers = offers.where((o) {
      if (o['offerType'] != "DirectDiscount") return false;

      final product = o['product'] ?? {};
      final name = (product['productName'] ?? '').toString().toLowerCase();
      final desc = (product['description'] ?? '').toString().toLowerCase();

      final double price = (product['price'] is num)
          ? (product['price'] as num).toDouble()
          : 0.0;

      final double discount = (o['discountValue'] is num)
          ? (o['discountValue'] as num).toDouble()
          : 0.0;

      final finalPrice = price - discount;

      return searchQuery.isEmpty ||
          name.contains(query) ||
          desc.contains(query) ||
          finalPrice.toString().contains(searchQuery);
    }).toList();

    // 🟦 عروض أخرى
    final otherOffers = offers.where((o) {
      if (o['offerType'] == "DirectDiscount") return false;

      final product = o['product'] ?? {};
      final name = (product['productName'] ?? '').toString().toLowerCase();
      final desc = (product['description'] ?? '').toString().toLowerCase();

      final double price = (product['price'] is num)
          ? (product['price'] as num).toDouble()
          : 0.0;

      final priceStr = price.toStringAsFixed(0);

      final textMatch = query.isEmpty ||
          name.contains(query) ||
          desc.contains(query) ||
          priceStr.contains(query);

      final numericMatch = queryNum == null ? false : (price == queryNum);

      return textMatch || numericMatch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 60, right: 12, left: 12),
      children: [
        // 🖼️ السلايدر
        if (sliders.isNotEmpty)
          SliderSection(
            sliders: sliders,
            sliderImages: sliderImages,
          ),

          const SizedBox(height: 20),
  
        // 🟥 الخصومات
if (discountOffers.isNotEmpty) ...[
 Padding(
  padding: EdgeInsets.only(
    right: MediaQuery.of(context).size.width * 0.02, // 3% من عرض الشاشة
    top: 8.0,
    bottom: 8.0,
  ),
  child: const Text(
    "الخصومات",
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
),

  SizedBox(
    height: MediaQuery.of(context).size.height * 0.30,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 12),
      children: discountOffers.map((offer) {
        final product = offer['product'] ?? {};

        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: OfferCard(
            offer: Map<String, dynamic>.from(offer),
            product: Map<String, dynamic>.from(product),
            searchQuery: searchQuery,
            isDiscount: true,
          ),
        );
      }).toList(),
    ),
  ),
],

       // 🟦 العروض الأخرى
if (otherOffers.isNotEmpty) ...[
 Padding(
  padding: EdgeInsets.only(
    right: MediaQuery.of(context).size.width * 0.02, // 3% من عرض الشاشة
    top: 8.0,
    bottom: 8.0,
  ),
  child: const Text(
    "اخر العروض",
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
),

  SizedBox(
    height: MediaQuery.of(context).size.height * 0.30,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 12),
      children: otherOffers.map((offer) {
        final product = offer['product'] ?? {};

        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: OfferCard(
            offer: Map<String, dynamic>.from(offer),
            product: Map<String, dynamic>.from(product),
            searchQuery: searchQuery,
            isDiscount: false,
          ),
        );
      }).toList(),
    ),
  ),
],

      
       // 🟩 الأقسام
for (var section in sections) ...[
  Builder(
    builder: (context) {
      final products = (section['products'] as List<dynamic>?) ?? [];

      final sectionName =
          (section['sectionName'] ?? '').toString().toLowerCase();

      final filtered = products.where((p) {
        final name = (p['productName'] ?? '').toString().toLowerCase();
        final desc = (p['description'] ?? '').toString().toLowerCase();
        final price = (p['price'] ?? '').toString();

        return query.isEmpty ||
            name.contains(query) ||
            desc.contains(query) ||
            price.contains(query) ||
            sectionName.contains(query);
      }).toList();

      if (filtered.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Padding(
  padding: EdgeInsets.only(
    right: MediaQuery.of(context).size.width * 0.02, // 3% من عرض الشاشة
    top: 8.0,
    bottom: 8.0,
  ),
  child: Text(
    section['sectionName'] ?? '',
    style: const TextStyle(
      fontSize: 24,                // 🔥 الحجم الجديد
      fontWeight: FontWeight.bold,
    ),
  ),
),

          // 🔥 المنتجات بشكل عمودي
          Column(
  children: filtered.map((p) {
    final product = p as Map<String, dynamic>;
    final productId = product['productId'];

    final offer = offers.firstWhere(
      (o) => o['product']?['productId'] == productId,
      orElse: () => null,
    );

    // إذا يوجد خصم مباشر → استخدم OfferCardVertical
    if (offer != null && offer['offerType'] == "DirectDiscount") {
      final double priceRaw = (product['price'] is num)
          ? (product['price'] as num).toDouble()
          : 0.0;

      final double discount = (offer['discountValue'] is num)
          ? (offer['discountValue'] as num).toDouble()
          : 0.0;

      final double finalPrice = priceRaw - discount;

      return Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.90,
          child: OfferCardVertical(
            offer: offer,
            product: product,
            priceRaw: priceRaw,
            finalPriceRaw: finalPrice,
            isDiscount: true,
            searchQuery: searchQuery,
          ),
        ),
      );
    }

    // بطاقة منتج عادية
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.90,
        child: ProductCard(
          product: product,
          searchQuery: searchQuery,
        ),
      ),
    );
  }).toList(),
),
        ],
      );
    },
  ),
],
      ],
    );
  }
}