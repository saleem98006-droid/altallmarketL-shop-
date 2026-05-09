import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/app_events.dart';
import '../../providers/home_products_provider.dart';
import 'slider_section.dart';
import 'offers_section.dart';
import 'product_card1.dart';
import '../SearchPage.dart';
import '../sectionProduct/section_products_page.dart';
import 'dart:async';

class HomeTabNew extends ConsumerStatefulWidget {
  const HomeTabNew({super.key});

  @override
  ConsumerState<HomeTabNew> createState() => _HomeTabNewState();
}

class _HomeTabNewState extends ConsumerState<HomeTabNew> {
  // ⭐ السلايدر
  List<dynamic>? sliders;
  bool isLoadingSliders = true;

  // ⭐ العروض + الخصومات
  List<dynamic>? offers;
  bool isLoadingOffers = true;

StreamSubscription<String>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadSliders();
    _loadOffers();
    ref.read(homeProductsProvider.notifier).loadSections();
    
  // 🟢 1) الاستماع لحدث التحديث
 _eventSubscription = AppEvents().stream.listen((event) {
  if (!mounted) return;

  // ⭐ تحديث الصفحة كاملة
  if (event == "refresh_home") {
    refreshHomeTab();
  }

  // ⭐ تحديث السلايدر فقط
  if (event == "refresh_sliders") {
    refreshSlidersOnly();
  }

  // ⭐ تحديث العروض فقط
  if (event == "refresh_offers") {
    refreshOffersOnly();
  }

  // ⭐ تحديث الأقسام + المنتجات فقط
  if (event == "refresh_sections") {
    refreshSectionsOnly();
  }
});
  }

 void refreshHomeTab() async {
  setState(() {
    isLoadingSliders = true;
    isLoadingOffers = true;

    sliders = null;
    offers = null;
  });

  await _loadSliders();
  await _loadOffers();
  await ref.read(homeProductsProvider.notifier).refreshSectionsOnly();
}
void refreshSlidersOnly() async {
  setState(() => isLoadingSliders = true);
  await _loadSliders();
}
void refreshOffersOnly() async {
  setState(() => isLoadingOffers = true);
  await _loadOffers();
}
void refreshSectionsOnly() async {
  await ref.read(homeProductsProvider.notifier).refreshSectionsOnly();
}

  // ============================
  // ⭐ تحميل السلايدر
  // ============================
 Future<void> _loadSliders() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;

    final response = await ApiService.getActiveSlidersByShop(
      shopId,
      page: 1,
      pageSize: 5,
    );

    if (!mounted) return;

    setState(() {
      sliders = response?["sliders"] ?? [];

      // ⭐ تحديث رابط الصورة مرة واحدة فقط
      sliders = sliders!.map((s) {
        if (s["imageUrl"] != null) {
          s["imageUrl"] = s["imageUrl"] + "?v=${DateTime.now().millisecondsSinceEpoch}";
        }
        return s;
      }).toList();

      isLoadingSliders = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => isLoadingSliders = false);
  }
}

  // ============================
  // ⭐ تحميل العروض + الخصومات
  // ============================
  Future<void> _loadOffers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? 0;

      final response = await ApiService.getOffersWithProducts(shopId);

      if (!mounted) return;

      setState(() {
        offers = response ?? [];
        isLoadingOffers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        offers = [];
        isLoadingOffers = false;
      });
    }
  }

  // ============================
  // ⭐ واجهة الصفحة
  // ============================
  @override
  Widget build(BuildContext context) {
    final homeProductsState = ref.watch(homeProductsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
       body: Stack(
  clipBehavior: Clip.none,
  children: [
    RefreshIndicator(
       color: Colors.white,
        backgroundColor: const Color(0xFF5A9BD5),
      onRefresh: () async {
        await _loadSliders();
        await _loadOffers();
        await ref.read(homeProductsProvider.notifier).refreshSectionsOnly();
      }, 
      child: ListView(
        padding: const EdgeInsets.only(top: 60, bottom: 12), // ← رفع المحتوى قليلاً
        children: [
          // ⭐ السلايدر
          if (isLoadingSliders)
            _buildSliderShimmer(context)
          else if (sliders != null && sliders!.isNotEmpty)
            SliderSection(
              sliders: sliders!,
              onSliderUpdated: _loadSliders,
            ),

          const SizedBox(height: 20),

          // ⭐ العروض + الخصومات
          if (isLoadingOffers)
            _buildOffersShimmer(context)
          else if (offers != null && offers!.isNotEmpty)
            _buildOffersAndDiscounts(context),

          const SizedBox(height: 20),

          // ⭐ الأقسام
          if (homeProductsState.isLoadingSections)
            _buildSectionsLoadingShimmer(context)
          else
            ...homeProductsState.visibleSections
                .map((sec) => _buildSection(sec as Map))
                .toList(),

          if (!isLoadingSliders &&
              !isLoadingOffers &&
              !homeProductsState.isLoadingSections &&
              (sliders == null || sliders!.isEmpty) &&
              (offers == null || offers!.isEmpty) &&
              homeProductsState.visibleSections.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Image.asset(
                  'assets/images/no_data.png',
                  width: MediaQuery.of(context).size.width * 0.9,
                  fit: BoxFit.contain,
                ),
              ),
            ),

          const SizedBox(height: 65),
        ],
      ),
    ),

    // ⭐ زر البحث
    _buildSearchBar(),
  ],
),
      ),
    );
  }

  // ============================
  // ⭐ بناء قسم واحد
  // ============================
  Widget _buildSection(Map sec) {
    final homeProductsState = ref.watch(homeProductsProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final sectionId = sec["sectionId"];
    final sectionName = sec["sectionName"];
    final prods = homeProductsState.products[sectionId] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ عنوان القسم + زر الكل
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                sectionName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

             GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectionProductsPage(
          section: Map<String, dynamic>.from(sec),  // ← الحل
        ),
      ),
    );
  },
  child: const Padding(
    padding: EdgeInsets.only(left: 10),
    child: Text(
      "الكل",
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        color: Color(0xFF5A9BD5),
      ),
    ),
  ),
),
            ],
          ),
        ),

        // ⭐ المنتجات
        SizedBox(
          height: screenHeight * 0.19,
          child: prods.isEmpty
              ? _buildSectionProductsShimmer(context)
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                      ref
                          .read(homeProductsProvider.notifier)
                          .loadProductsForSection(sectionId);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: prods.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: prods[index],
                        searchQuery: "",
                        onUpdated: () => ref
                            .read(homeProductsProvider.notifier)
                            .refreshSection(sectionId),
                      );
                    },
                  ),
                ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ============================
  // ⭐ العروض + الخصومات
  // ============================
  Widget _buildOffersAndDiscounts(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final discountOffers = (offers ?? [])
        .where((o) => o['offerType'] == "DirectDiscount")
        .toList();

    final otherOffers = (offers ?? [])
        .where((o) => o['offerType'] != "DirectDiscount")
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (discountOffers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "الخصومات",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: screenHeight * 0.27,
            child: OffersSection(
              offers: discountOffers,
              searchQuery: "",
              onUpdated: _loadOffers,
            ),
          ),
        ],

        const SizedBox(height: 0),

        if (otherOffers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "العروض",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: screenHeight * 0.27,
            child: OffersSection(
              offers: otherOffers,
              searchQuery: "",
              onUpdated: _loadOffers,
            ),
          ),
        ],
      ],
    );
  }


  //=============================
  //البحث
  //=============================
  Widget _buildSliderShimmer(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            height: h * 0.25,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (_) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersShimmer(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w * 0.66;
    final cardH = cardW * 0.56;

    Widget section(String _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 22,
              width: 130,
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(
              height: cardH,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 3,
                itemBuilder: (context, index) => Container(
                  width: cardW,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        );

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          section('discount'),
          section('offers'),
        ],
      ),
    );
  }

  Widget _buildSectionsLoadingShimmer(BuildContext context) {
    return Column(
      children: List.generate(2, (_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildSectionProductsShimmer(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionProductsShimmer(BuildContext context) {
    final itemH = MediaQuery.of(context).size.height * 0.19;

    return SizedBox(
      height: itemH,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 4,
        itemBuilder: (_, __) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 90,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 50,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
  return Positioned(
    top: -24,
    left: 20,
    right: 20,
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  SearchPage(),
          ),
        );
      },
      child: AbsorbPointer(
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(30),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              enabled: false,
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
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF5A9BD5),
                    width: 3,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF5A9BD5),
                    width: 3,
                  ),
                ),

                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF5A9BD5),
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}