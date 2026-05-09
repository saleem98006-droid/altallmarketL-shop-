import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/api_config.dart';
import '../../providers/router_provider.dart';

class ProductCardSmall extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductCardSmall({
    super.key,
    required this.product,
  });

  @override
  State<ProductCardSmall> createState() => _ProductCardSmallState();
}

class _ProductCardSmallState extends State<ProductCardSmall> {
  int currentIndex = 0;
  Timer? _timer;

  late String img1;
  late String img2;
  late String img3;

  late List<String> validImages;

  @override
  void initState() {
    super.initState();

    img1 = widget.product['imageUrl1']?.toString() ?? '';
    img2 = widget.product['imageUrl2']?.toString() ?? '';
    img3 = widget.product['imageUrl3']?.toString() ?? '';

    validImages = [img1, img2, img3].where((e) => e.isNotEmpty).toList();
    _prepareImages();

    if (validImages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted) return;
        setState(() {
          currentIndex = (currentIndex + 1) % validImages.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepareImages() {
    validImages.clear();

    final raw1 = widget.product['imageUrl1']?.toString() ?? '';
    final raw2 = widget.product['imageUrl2']?.toString() ?? '';
    final raw3 = widget.product['imageUrl3']?.toString() ?? '';

    void addIfValid(String url) {
      if (url.isEmpty) return;
      if (url.toLowerCase() == 'null') return;
      final cacheBusted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      validImages.add(cacheBusted);
    }

    addIfValid(raw1);
    addIfValid(raw2);
    addIfValid(raw3);

    if (validImages.isEmpty) {
      validImages.add('');
    }

    currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final double price =
        double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;

    final String? currentImageUrl =
        validImages.isNotEmpty ? validImages[currentIndex] : null;

    final bool isActive =
        product['isActive'] == true || product['active'] == true;

    return GestureDetector(
      onTap: () async {
        await context.push(
          AppRoutes.productDetail,
          extra: {
            'product': product,
            'offer': null,
          },
        );
        if (mounted) {
          setState(() => _prepareImages());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // ⭐ صورة مع تلاشي + أبيض وأسود إذا غير مفعّل
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: ClipRRect(
                  key: ValueKey<int>(currentIndex),
                  borderRadius: BorderRadius.circular(12),
                  child: currentImageUrl != null && currentImageUrl.isNotEmpty
                      ? ColorFiltered(
                          colorFilter: isActive
                              ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                )
                              : const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      1, 0,
                                ]),
                          child: CachedNetworkImage(
                            imageUrl: ApiConfig.baseUrl + currentImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,

                            // ⭐ Placeholder بإضاءة (Glow)
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
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
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image,
                              size: 40, color: Colors.grey),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ⭐ الاسم
            Text(
              product['productName'] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            // ⭐ السعر
            Text(
              "$price ل.س",
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: isActive ? const Color(0xFF5A9BD5) : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
