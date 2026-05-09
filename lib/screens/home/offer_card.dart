import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../providers/router_provider.dart';
import 'highlight_text.dart';

class OfferCard extends StatefulWidget {
  final Map<String, dynamic> offer;
  final Map<String, dynamic> product;
  final String searchQuery;
  final bool isDiscount;

  const OfferCard({
    super.key,
    required this.offer,
    required this.product,
    required this.searchQuery,
    required this.isDiscount,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  Timer? countdownTimer;
  Timer? _imageTimer;
  Duration? remaining;

  int currentIndex = 0;
  late final List<Uint8List> validImages;

  @override
  void initState() {
    super.initState();
    _initImages();
    _startCountdown();
  }

  void _initImages() {
    validImages = [];

    final fields = [
      widget.product['image'],
      widget.product['image2'],
      widget.product['image3'],
      widget.product['Image'],
      widget.product['Image_2'],
      widget.product['Image_3'],
    ];

    for (var raw in fields) {
      final decoded = _decodeBase64(raw);
      if (decoded != null) {
        validImages.add(decoded);
      }
    }

    if (validImages.length > 1) {
      _imageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!mounted) return;
        setState(() {
          currentIndex = (currentIndex + 1) % validImages.length;
        });
      });
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _imageTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final endStr = widget.offer['endDate']?.toString();
    if (endStr == null) return;

    final endDate = DateTime.tryParse(endStr);
    if (endDate == null) return;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = endDate.difference(now);
      if (diff.isNegative) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          remaining = Duration.zero;
        });
      } else {
        if (!mounted) return;
        setState(() {
          remaining = diff;
        });
      }
    });
  }

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Uint8List? _decodeBase64(dynamic rawImage) {
    if (rawImage == null) return null;
    try {
      if (rawImage is String && rawImage.isNotEmpty) {
        final cleaned = rawImage.split(',').last;
        return base64Decode(cleaned);
      } else if (rawImage is Map && rawImage.containsKey('data')) {
        final cleaned = rawImage['data'].toString().split(',').last;
        return base64Decode(cleaned);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _getOfferDetails(
      Map<String, dynamic> offer, bool isDiscount, double price, double finalPrice) {
    if (isDiscount) {
      final discountValue = offer['discountValue'];
      if (discountValue != null && price > 0) {
        final percent = ((price - finalPrice) / price * 100).round();
        return "خصم مباشر $percent% (${discountValue} ل.س)";
      }
      return "خصم مباشر";
    } else {
      final buyQty = offer['buyQuantity'];
      final getQty = offer['getQuantity'];
      final freeProductName = offer['freeProductName'];

      if (buyQty != null && getQty != null) {
        if (freeProductName != null && freeProductName.toString().isNotEmpty) {
          return "اشترِ $buyQty واحصل على $freeProductName مجاناً";
        }
        return "اشترِ $buyQty واحصل على $getQty مجاناً";
      }

      if (offer['label'] != null && offer['label'].toString().isNotEmpty) {
        return offer['label'].toString();
      }

      return "عرض مميز";
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final double price = (widget.product['price'] is num)
        ? (widget.product['price'] as num).toDouble()
        : 0.0;

    final double finalPrice = widget.isDiscount
        ? (price -
                ((widget.offer['discountValue'] is num)
                    ? (widget.offer['discountValue'] as num).toDouble()
                    : 0.0))
            .clamp(0.0, double.infinity)
        : price;

    final productName = widget.product['productName']?.toString() ??
        widget.product['ProductName']?.toString() ??
        '';

    final currentImage =
        validImages.isNotEmpty ? validImages[currentIndex] : null;

    final bool showTimer =
        remaining != null && remaining! <= const Duration(hours: 6);

    const Color timerBackgroundColor = Colors.black54;

    final imageWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: ClipRRect(
        key: ValueKey<int>(currentIndex),
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: currentImage != null
              ? Image.memory(
                  currentImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image,
                      size: 80, color: Colors.grey),
                ),
        ),
      ),
    );

    final offerDetails =
        _getOfferDetails(widget.offer, widget.isDiscount, price, finalPrice);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () async {
        final id = widget.product['productId'] ??
            widget.product['ProductID'] ??
            widget.product['id'];

        if (id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ المنتج غير صالح")),
          );
          return;
        }

        final fullProduct = await ApiService.getProductById(id);

        if (fullProduct != null) {
              await context.push(
                AppRoutes.productDetail,
                extra: {
                  'product': fullProduct,
                  'offer': widget.offer,
                },
          );
        }
      },
      child: Container(
        width: screenWidth * 0.6,
        height: screenHeight * 0.2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة + العداد
            Stack(
              children: [
                SizedBox(
                  height: screenHeight * 0.12,
                  child: imageWidget,
                ),
                if (showTimer)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: timerBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${_formatDuration(remaining!)} ⏳",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFF0000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // النصوص تحت الصورة
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightText(
                      text: productName,
                      query: widget.searchQuery,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),

                    const SizedBox(height: 4),

                    if (widget.isDiscount) ...[
                      Text(
                        "${_formatPrice(price)} ل.س",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.black54,
                          color: Color(0xFFFF0000),
                          fontSize: 16,
                          decorationThickness: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_formatPrice(finalPrice)} ل.س",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 36,
                        child: Text(
                          offerDetails,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
  () {
    final buyQty = widget.offer['buyQuantity'];

    // إذا كان العرض Buy X → السعر الجديد = price × buyQuantity
    if (buyQty != null && buyQty is int && buyQty > 0) {
      final totalPrice = price * buyQty;
      return "${_formatPrice(totalPrice)} ل.س";
    }

    // غير ذلك → السعر العادي
    return "${_formatPrice(price)} ل.س";
  }(),
  style: const TextStyle(
    fontSize: 18,
    color: Colors.green,
  ),
),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}