import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OfferDetailScreen extends StatelessWidget {
  final Map<String, dynamic> offer;
  final Map<String, dynamic> product;

  const OfferDetailScreen({
    super.key,
    required this.offer,
    required this.product,
  });

  // 🟢 دالة مساعدة لتحويل أي قيمة إلى نص آمن
  String safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // 🟢 دالة لبناء الصورة بشكل آمن
  Widget buildImage(dynamic imageField) {
    if (imageField is String && imageField.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(imageField),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
        );
      } catch (_) {
        return const Icon(Icons.broken_image, size: 120, color: Colors.grey);
      }
    } else if (imageField is Map && imageField['data'] is String) {
      try {
        return Image.memory(
          base64Decode(imageField['data']),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
        );
      } catch (_) {
        return const Icon(Icons.broken_image, size: 120, color: Colors.grey);
      }
    } else if (imageField is Map && imageField['url'] is String) {
      return Image.network(
        imageField['url'],
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
      );
    }
    return const Icon(Icons.image, size: 120, color: Colors.grey);
  }

  // 🟢 النص المناسب للعرض
  String _getOfferLabel(Map<String, dynamic> offer) {
    final type = offer['offerType'];
    final buyQty = (offer['buyQuantity'] is num) ? (offer['buyQuantity'] as num).toInt() : 0;
    final getQty = (offer['getQuantity'] is num) ? (offer['getQuantity'] as num).toInt() : 0;
    final freeName = safeString(offer['freeProductName']);

    if (type == "BuyXGetY") {
      return "اشترِ $buyQty واحصل على $getQty × $freeName";
    } else if (type == "FreeItem") {
      return "اشترِ $buyQty واحصل على $freeName مجانًا";
    } else if (type == "DirectDiscount") {
      return "خصم مباشر";
    }
    return "عرض خاص";
  }

  @override
  Widget build(BuildContext context) {
    final double price = (product['price'] is num) ? (product['price'] as num).toDouble() : 0.0;
    final double discountValue = (offer['discountValue'] is num) ? (offer['discountValue'] as num).toDouble() : 0.0;
    final double finalPrice = price - discountValue;

    final imageWidget = buildImage(product['image']);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: imageWidget),
                        const SizedBox(height: 16),
                        Text(
                          safeString(product['productName']),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getOfferLabel(offer),
                          style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (offer['offerType'] == "DirectDiscount") ...[
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
                        ] else ...[
                          Text(
                            "السعر: ${price.toInt()} ل.س",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (safeString(product['description']).isNotEmpty)
                          Text(
                            safeString(product['description']),
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                      ],
                    ),
                  ),
                ),

                // 🟢 أزرار تعديل وحذف أسفل الصفحة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/editOffer',
                          arguments: {"offer": offer, "product": product},
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("تعديل"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    ElevatedButton.icon(
  onPressed: () async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد أنك تريد حذف هذا العرض؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // إلغاء
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // 👈 استدعاء API الحذف
                final result = await ApiService.deleteOffer(offer['offerId']);
                if (result != null && result['success'] == true) {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حذف العرض بنجاح ✅")),
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home', // 👈 اسم صفحة الرئيسية
                    (route) => false,
                  );
                } else {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("فشل حذف العرض ❌")),
                  );
                }
              },
              child: const Text("حذف"),
            ),
          ],
        );
      },
    );
  },
  icon: const Icon(Icons.delete),
  label: const Text("حذف"),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
),

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

