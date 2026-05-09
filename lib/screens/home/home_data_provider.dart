import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class HomeDataProvider {
  // 🟦 Singleton
  static final HomeDataProvider _instance = HomeDataProvider._internal();
  factory HomeDataProvider() => _instance;
  HomeDataProvider._internal();

  // 🟦 Memory Cache
  Map<String, dynamic>? sections;
  Map<String, dynamic>? uncategorized;
  List<dynamic>? offers;
  List<dynamic>? sliders;
  List<ImageProvider>? sliderImages;

  // 🟦 Pagination للمنتجات فقط
  int page = 1;
  final int pageSize = 10;
  bool hasMore = true;
  bool isLoadingMore = false;

  bool _isLoading = false;
  bool _hasLoaded = false;

  // 🟦 مسح الكاش
  void clearCache() {
    sections = null;
    uncategorized = null;
    offers = null;
    sliders = null;
    sliderImages = null;

    // إعادة ضبط الباجينيشن
    page = 1;
    hasMore = true;
    isLoadingMore = false;

    _hasLoaded = false;
  }

  // 🟦 تحميل الصفحة الأولى
  Future<bool> loadSections(int shopId) async {
    if (_hasLoaded) return true;
    if (_isLoading) return false;

    _isLoading = true;

    try {
      // 🔥 تحميل الصفحة الأولى من المنتجات فقط
      final response = await ApiService.getSectionsWithProducts(
        shopId,
        page: page,
        pageSize: pageSize,
      );

      // تحميل باقي البيانات كما هي
      final uncategorizedResponse =
          await ApiService.getUncategorizedProducts(shopId);
      final offersResponse = await ApiService.getOffersWithProducts(shopId);
      final slidersResponse = await ApiService.getActiveSlidersByShop(shopId);

      // فك صور السلايدر
      final images = slidersResponse?.map<ImageProvider>((slider) {
        final base64 = slider['image'];
        if (base64 != null && base64.isNotEmpty) {
          try {
            return MemoryImage(base64Decode(base64));
          } catch (_) {
            return const AssetImage('assets/images/Add1.png');
          }
        }
        return const AssetImage('assets/images/Add1.png');
      }).toList();

      // تخزين البيانات
      sections = response;
      uncategorized = uncategorizedResponse;
      offers = offersResponse;
      sliders = slidersResponse;
      sliderImages = images;

      // 🔥 إذا عدد المنتجات أقل من pageSize → لا يوجد المزيد
      final List<dynamic> firstPageSections =
          response?["sections"] ?? [];

      final int productCount = firstPageSections.fold(
        0,
        (sum, sec) => sum + ((sec["products"] as List?)?.length ?? 0),
      );

      if (productCount < pageSize) {
        hasMore = false;
      }

      _hasLoaded = true;
      _isLoading = false;
      return true;
    } catch (e) {
      print("❌ Error loading home data: $e");
      _isLoading = false;
      return false;
    }
  }

  // 🟦 تحميل المزيد من المنتجات (Pagination)
  Future<bool> loadMoreSections(int shopId) async {
    if (!hasMore || isLoadingMore) return false;

    isLoadingMore = true;
    page++;

    try {
      final response = await ApiService.getSectionsWithProducts(
        shopId,
        page: page,
        pageSize: pageSize,
      );

      final List<dynamic> newSections = response?["sections"] ?? [];

      // حساب عدد المنتجات الجديدة
      final int newProductsCount = newSections.fold(
        0,
        (sum, sec) => sum + ((sec["products"] as List?)?.length ?? 0),
      );

      // إذا لا يوجد منتجات جديدة → توقف
      if (newProductsCount == 0) {
        hasMore = false;
        isLoadingMore = false;
        return false;
      }

      // دمج الأقسام الجديدة مع القديمة
      final oldSections = sections?["sections"] as List<dynamic>? ?? [];

      for (var newSec in newSections) {
        final int secId = newSec["sectionId"];
        final oldSec = oldSections.firstWhere(
          (s) => s["sectionId"] == secId,
          orElse: () => null,
        );

        if (oldSec != null) {
          // دمج المنتجات
          (oldSec["products"] as List).addAll(newSec["products"]);
        } else {
          // قسم جديد بالكامل
          oldSections.add(newSec);
        }
      }

      sections!["sections"] = oldSections;

      // إذا أقل من pageSize → لا يوجد المزيد
      if (newProductsCount < pageSize) {
        hasMore = false;
      }

      isLoadingMore = false;
      return true;
    } catch (e) {
      print("❌ Error loading more sections: $e");
      isLoadingMore = false;
      return false;
    }
  }
}
