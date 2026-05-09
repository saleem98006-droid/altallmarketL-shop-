import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class HomeProductsRepository {
  Future<int> getShopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('shopId') ?? 0;
  }

  Future<List<dynamic>> getSectionsByShop(int shopId) async {
    final response = await ApiService.getSectionsShop(shopId);
    return response?['sections'] ?? [];
  }

  Future<Map<String, dynamic>?> getProductsBySection({
    required int sectionId,
    required int page,
    int pageSize = 6,
  }) {
    return ApiService.getProductsBySectionPagedIneffective(
      sectionId,
      page,
      pageSize,
    );
  }
}
