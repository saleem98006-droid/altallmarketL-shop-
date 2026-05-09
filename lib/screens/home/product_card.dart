
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../providers/router_provider.dart';
import 'highlight_text.dart';



class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final String searchQuery;

  const ProductCard({
    super.key,
    required this.product,
    required this.searchQuery,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int currentIndex = 0;
  Timer? _timer;

  late final List<String> imageUrls;

  @override
  void initState() {
    super.initState();

    // استخراج الصور من Base64
   imageUrls = [];

final fields = [
  widget.product['imageUrl1'],
  widget.product['imageUrl2'],
  widget.product['imageUrl3'],
];

for (var url in fields) {
  if (url is String && url.trim().isNotEmpty) {
    imageUrls.add(url.trim());
  }
}

    // تشغيل السلايدر إذا كان هناك أكثر من صورة
   if (imageUrls.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!mounted) return;
        setState(() {
          currentIndex = (currentIndex + 1) % imageUrls.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   final String? currentImageUrl =
    imageUrls.isNotEmpty ? imageUrls[currentIndex] : null;

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final name = widget.product['productName']?.toString() ??
        widget.product['ProductName']?.toString() ??
        '';

    final double price = (widget.product['price'] is num)
        ? (widget.product['price'] as num).toDouble()
        : double.tryParse(widget.product['price']?.toString() ?? '') ?? 0.0;

    // 🔥 قراءة حالة التفعيل
    final bool isActive = widget.product['isActive'] == true;

    return GestureDetector(
      onTap: () async {
        await context.push(
          AppRoutes.productDetail,
          extra: {
            'product': widget.product,
            'offer': null,
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,

        // 🔥 الخلفية حسب حالة التفعيل
        color: isActive ? const Color(0xFFF6FCFC) : Colors.grey[300],

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: SizedBox(
          height: screenHeight * 0.16,
          width: screenWidth * 0.9,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
 // تفاصيل المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // الاسم
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: screenHeight * 0.15 * 0.15,
                        ),
                        child: HighlightText(
                          text: name,
                          query: widget.searchQuery,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // السعر
                    Align(
                      alignment: Alignment.centerRight,
                      child: HighlightText(
                        text: "$price ل.س",
                        query: widget.searchQuery,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

             
// صورة المنتج (يمين)
              SizedBox(
                width: screenWidth * 0.30,
                height: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: currentImageUrl  != null
                        ? ColorFiltered(
                            // 🔥 جعل الصورة باهتة إذا كان غير فعال
                            colorFilter: isActive
                                ? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.multiply,
                                  )
                                : const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  ),
                            child: CachedNetworkImage(
  imageUrl: ApiConfig.baseUrl + currentImageUrl!,
  fit: BoxFit.cover,
  width: double.infinity,
  height: double.infinity,
  placeholder: (context, url) => _buildShimmerPlaceholder(),
  errorWidget: (context, url, error) => const Icon(
    Icons.broken_image,
    size: 40,
    color: Colors.grey,
  ),
),
                          )
                        : Container(
                            key: const ValueKey<String>("no_image"),
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
             
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildShimmerPlaceholder() {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.3, end: 0.9),
    duration: const Duration(milliseconds: 800),
    curve: Curves.easeInOut,
    builder: (context, value, child) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.withOpacity(value),
              Colors.grey.withOpacity(value - 0.2),
              Colors.grey.withOpacity(value),
            ],
          ),
        ),
      );
    },
    onEnd: () {
      // إعادة تشغيل الأنيميشن
    },
  );
}
}
