import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../config/api_config.dart';
import '../providers/router_provider.dart';

class ProductCard extends StatefulWidget {
  final Map product;
  final String searchQuery;
  final Function onUpdated;

  const ProductCard({
    super.key,
    required this.product,
    required this.searchQuery,
    required this.onUpdated,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _currentImageIndex = 0;
  Timer? _timer;

  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();

    _prepareImages();

    if (imageUrls.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % imageUrls.length;
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
  imageUrls.clear();

  // قراءة الصور من المنتج
  final raw1 = widget.product['imageUrl1'];
  final raw2 = widget.product['imageUrl2'];
  final raw3 = widget.product['imageUrl3'];

  // دالة مساعدة لإضافة الصورة فقط إذا كانت صالحة
  void addIfValid(dynamic url) {
    if (url == null) return;
    if (url.toString().trim().isEmpty) return;
    if (url.toString().toLowerCase() == "null") return;
    imageUrls.add(url.toString());
  }

  addIfValid(raw1);
  addIfValid(raw2);
  addIfValid(raw3);

  // إذا بقيت فارغة → نضيف صورة فارغة
  if (imageUrls.isEmpty) {
    imageUrls.add(""); // صورة فارغة
  }
}

  Widget highlightText(
    String? text,
    String query, {
    int maxLines = 1,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    Color highlightColor = Colors.red,
  }) {
    final safeText = (text ?? '').toString();

    if (query.isEmpty) {
      return Text(
        safeText,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: fontSize, fontWeight: fontWeight, color: color),
      );
    }

    final lowerText = safeText.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(
        safeText,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: fontSize, fontWeight: fontWeight, color: color),
      );
    }

    int endIndex = startIndex + lowerQuery.length;
    if (endIndex > safeText.length) {
      endIndex = safeText.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
            fontSize: fontSize, fontWeight: fontWeight, color: color),
        children: [
          TextSpan(text: safeText.substring(0, startIndex)),
          TextSpan(
            text: safeText.substring(startIndex, endIndex),
            style: TextStyle(
                color: highlightColor, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: safeText.substring(endIndex)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final cardWidth = screenWidth * 0.374;
    final cardHeight = screenHeight * 0.158;
    final imageHeight = screenHeight * 0.097;

    final bool isActive =
        widget.product['isActive'] == true || widget.product['active'] == true;

    final currentImageUrl = imageUrls.isNotEmpty
    ? imageUrls[_currentImageIndex % imageUrls.length]
    : "";

    return GestureDetector(
      onTap: () async {
        final updated = await context.push(
          AppRoutes.productDetail,
          extra: {
            'product': widget.product,
            'offer': null,
          },
        );
        if (updated == true) widget.onUpdated();
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ صورة المنتج مع CachedNetworkImage + AnimatedSwitcher
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: ClipRRect(
                key: ValueKey(currentImageUrl),
                borderRadius: BorderRadius.circular(15),
                child: currentImageUrl.isEmpty
                    ? Container(
                        width: cardWidth,
                        height: imageHeight,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      )
                    : ColorFiltered(
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
                          width: cardWidth,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: cardWidth,
                            height: imageHeight,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: cardWidth,
                            height: imageHeight,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                      ),
              ),
            ),

            SizedBox(height: screenHeight * 0.0108),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: highlightText(
                widget.product['productName'] ??
                    widget.product['ProductName'] ??
                    '',
                widget.searchQuery,
                fontSize: screenWidth * 0.037,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: screenHeight * 0.0054),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: highlightText(
                "${widget.product['price']} ل.س",
                widget.searchQuery,
                fontSize: screenWidth * 0.033,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF5A9BD5) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}