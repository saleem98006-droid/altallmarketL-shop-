import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../providers/router_provider.dart';
import 'dart:async';
class OffersSection extends StatefulWidget {
  final List offers;
  final String searchQuery;
  final VoidCallback onUpdated;

  const OffersSection({
    super.key,
    required this.offers,
    required this.searchQuery,
    required this.onUpdated,
  });

  @override
  State<OffersSection> createState() => _OffersSectionState();
}

class _OffersSectionState extends State<OffersSection> {
  int _offerImageIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _startImageTimer();
    });
  }

  void _startImageTimer() {
   Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _offerImageIndex++;
      });
    });
  }

  /// ⭐ دالة آمنة لتحويل أي قيمة إلى double
  double safeToDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    if (value is Map) {
      if (value.containsKey("amount")) {
        return safeToDouble(value["amount"]);
      }
      if (value.containsKey("value")) {
        return safeToDouble(value["value"]);
      }
    }

    return 0.0;
  }

  /// دالة النص حسب نوع العرض
  String _getOfferLabel(Map<String, dynamic> offer) {
    final type = offer['offerType'];

    final buyQty = safeToDouble(offer['buyQuantity']).toInt();
    final getQty = safeToDouble(offer['getQuantity']).toInt();
    final freeName = offer['freeProductName']?.toString() ?? "منتج مجاني";

    if (type == "BuyXGetY") {
      return "اشترِ $buyQty واحصل على $getQty $freeName";
    } else if (type == "FreeItem") {
      return "اشترِ $buyQty واحصل على $freeName مجانًا";
    } else if (type == "DirectDiscount") {
      return "خصم مباشر";
    }
    return "عرض خاص";
  }

  /// بطاقة العرض — الآن آمنة 100%
  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final product = offer['product'] ?? {};

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final cardWidth = screenWidth * 0.56;
    final cardHeight = screenHeight * 0.254;

    final imageWidth = screenWidth * 0.56;
    final imageHeight = screenHeight * 0.1458;

    final spaceImageToName = screenHeight * 0.0108;
    final spaceNameToOffer = screenHeight * 0.0054;

    final nameFont = (screenWidth * 0.042).clamp(13.0, 18.0).toDouble();
    final offerFont = (screenWidth * 0.0327).clamp(10.0, 14.0).toDouble();

    // ⭐ السعر والخصم آمنين الآن
    final double price = safeToDouble(product['price']);
    final double discountValue = safeToDouble(offer['discountValue']);
    final double finalPrice = (price - discountValue).clamp(0.0, double.infinity);

    final productName = product['productName']?.toString() ??
        product['ProductName']?.toString() ??
        '';

    final offerLabel = _getOfferLabel(offer);

    String formatPrice(double value) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }

    // ⭐ الصور كما في القديم
    final List<String> imageUrls = [];
    if (product["imageUrl1"] != null) imageUrls.add(product["imageUrl1"]);
    if (product["imageUrl2"] != null) imageUrls.add(product["imageUrl2"]);
    if (product["imageUrl3"] != null) imageUrls.add(product["imageUrl3"]);
    if (imageUrls.isEmpty) imageUrls.add("");

    final currentImageUrl = imageUrls[_offerImageIndex % imageUrls.length];

    final isDiscount = offer['offerType'] == "DirectDiscount";

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: () async {
          final id = product['productId'] ??
              product['ProductID'] ??
              product['id'];

          if (id == null) return;

          final fullProduct = await ApiService.getProductById(id);
          if (fullProduct != null) {
                final updated = await context.push(
                  AppRoutes.productDetail,
                  extra: {
                    'product': fullProduct,
                    'offer': offer,
                  },
            );
            if (updated == true) widget.onUpdated();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final safeImageHeight = imageHeight
                .clamp(constraints.maxHeight * 0.42, constraints.maxHeight * 0.62)
                .toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐ صورة
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: ClipRRect(
                    key: ValueKey(currentImageUrl),
                    borderRadius: BorderRadius.circular(15),
                    child: currentImageUrl.isEmpty
                        ? Container(
                            width: imageWidth,
                            height: safeImageHeight,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.7),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.image, size: 40, color: Colors.white),
                          )
                        : CachedNetworkImage(
                            imageUrl: ApiConfig.baseUrl + currentImageUrl,
                            width: imageWidth,
                            height: safeImageHeight,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: imageWidth,
                              height: safeImageHeight,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.7),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: imageWidth,
                              height: safeImageHeight,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                  ),
                ),

                SizedBox(height: spaceImageToName),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ⭐ اسم المنتج
                        Text(
                          productName,
                          style: TextStyle(
                            fontSize: nameFont,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: spaceNameToOffer),

                        // ⭐ العرض / الخصم
                        if (isDiscount) ...[
                          Text(
                            "${formatPrice(price)} ل.س",
                            style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: const Color(0xFFff0000),
                              fontSize: offerFont,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spaceNameToOffer),
                          Text(
                            "${formatPrice(finalPrice)} ل.س",
                            style: TextStyle(
                              fontSize: offerFont,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5A9BD5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          Expanded(
                            child: Text(
                              offerLabel,
                              style: TextStyle(
                                fontSize: offerFont,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFff0000),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: spaceNameToOffer),
                          Text(
                            "${formatPrice(price)} ل.س",
                            style: TextStyle(
                              fontSize: offerFont,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5A9BD5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.27,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.offers.length,
        itemBuilder: (context, index) {
          final offer = widget.offers[index];
          return _buildOfferCard(offer);
        },
      ),
    );
  }
}