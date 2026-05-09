import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'product_card.dart';
import 'offer_card.dart';

class ShopOrderItemsList extends StatelessWidget {
  final List<dynamic> items;
final bool canEdit;  
  // ⭐ إضافة Callback لإرسال التعديل للصفحة الأم
  final Function(int shopOrderItemId, int newQuantity) onQuantityChanged;

  const ShopOrderItemsList({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    required this.canEdit, 
  });

  static final Map<int, Map<String, dynamic>> _detailsCache = {};

  Future<Map<String, dynamic>?> _fetchItemDetails(
      int sourceId, String sourceType) async {
    if (_detailsCache.containsKey(sourceId)) {
      return _detailsCache[sourceId];
    }

    final details =
        await ApiService.getItemDetails(sourceId: sourceId, sourceType: sourceType);

    if (details != null && details['success'] == true) {
      _detailsCache[sourceId] = details;
      return details;
    }
    return null;
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final sourceId = item['sourceID'] as int;
    final sourceType = item['sourceType'] as String;
    final quantity = item['quantity'] as int;
    final shopOrderItemId = item['shopOrderItemID'];

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchItemDetails(sourceId, sourceType),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            title: Text(
              "جاري تحميل التفاصيل...",
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          );
        }

        final details = snapshot.data!;

        if (details['type'] == "Product") {
          return ProductCard(
            details: details,
            quantity: quantity,
             canEdit: canEdit,
            onQuantityChanged: (newQty) {
              onQuantityChanged(shopOrderItemId, newQty);
            },
          );
        } else if (details['type'] == "Offer") {
          return OfferCard(
            details: details,
            quantity: quantity,
            canEdit: canEdit,
            onQuantityChanged: (newQty) {
              onQuantityChanged(shopOrderItemId, newQty);
            },
          );
         
        } else {
          return const ListTile(
            title: Text(
              "عنصر غير معروف",
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildItemTile(item),
        );
      },
    );
  }
}