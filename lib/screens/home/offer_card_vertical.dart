import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/router_provider.dart';
import 'highlight_text.dart';

class OfferCardVertical extends StatefulWidget {
  final Map<String, dynamic> offer;
  final Map<String, dynamic> product;
  final double priceRaw;
  final double finalPriceRaw;
  final bool isDiscount;
  final String searchQuery;

  const OfferCardVertical({
    super.key,
    required this.offer,
    required this.product,
    required this.priceRaw,
    required this.finalPriceRaw,
    required this.isDiscount,
    required this.searchQuery,
  });

  @override
  State<OfferCardVertical> createState() => _OfferCardVerticalState();
}

class _OfferCardVerticalState extends State<OfferCardVertical> {
  int currentIndex = 0;
  Timer? _timer;
  late final List<Uint8List> validImages;

  @override
  void initState() {
    super.initState();

    // استخراج الصور من Base64
    validImages = [];
    final fields = [
  widget.product['image'],
  widget.product['image2'],
  widget.product['image3'],
];

    for (var img in fields) {
      if (img is String && img.isNotEmpty) {
        try {
          validImages.add(base64Decode(img));
        } catch (_) {}
      }
    }

    // تشغيل السلايدر إذا كان هناك أكثر من صورة
    if (validImages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
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

  String _formatPrice(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? currentImage =
        validImages.isNotEmpty ? validImages[currentIndex] : null;

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final productName =
        widget.product['productName']?.toString() ?? "منتج";

    return GestureDetector(
      onTap: () async {
        await context.push(
          AppRoutes.productDetail,
          extra: {
            'product': widget.product,
            'offer': widget.offer,
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        color: const Color(0xFFF6FCFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: SizedBox(
          height: screenHeight * 0.16,
          width: screenWidth * 0.9,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
             // صورة المنتج
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
                        child: currentImage != null
                            ? Image.memory(
                                currentImage,
                                key: ValueKey<int>(currentIndex), // 🔥 المفتاح هنا
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
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

              const SizedBox(width: 12),

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
                          top: screenHeight * 0.16 * 0.15,
                        ),
                        child: HighlightText(
                          text: productName,
                          query: widget.searchQuery,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // السعر قبل الخصم
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${_formatPrice(widget.priceRaw)} ل.س",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.black,
                          color: Color(0xFFFF0000),
                          fontSize: 16,
                          decorationThickness: 2,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // السعر بعد الخصم
                    Align(
                      alignment: Alignment.centerRight,
                      child: HighlightText(
                        text: "${_formatPrice(widget.finalPriceRaw)} ل.س",
                        query: widget.searchQuery,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}