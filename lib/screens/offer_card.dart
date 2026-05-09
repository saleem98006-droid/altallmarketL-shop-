import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import 'dart:async';
import '../widgets/loading_dots_widget.dart';

class OfferCard extends StatefulWidget {
  final Map<String, dynamic> details;
  final int quantity;
final bool canEdit;
  // ⭐ إضافة الكولباك مثل بطاقة المنتج
  final Function(int newQty) onQuantityChanged;

  const OfferCard({
    super.key,
    required this.details,
    required this.quantity,
    required this.canEdit,
    required this.onQuantityChanged,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
 int _currentImageIndex = 0;
late List<String> _imageUrls;
  @override
void initState() {
  super.initState();

  final productDetails = widget.details['productDetails'];

  _imageUrls = [
    productDetails?['imageUrl1'],
    productDetails?['imageUrl2'],
    productDetails?['imageUrl3'],
  ]
      .where((url) => url != null && url.toString().trim().isNotEmpty)
      .map((url) => url as String)
      .toList();

  if (_imageUrls.length > 1) {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _currentImageIndex =
            (_currentImageIndex + 1) % _imageUrls.length;
      });
    });
  }
}

  // ⭐ الديالوغ الخاص بتحديد الكمية (نفس بطاقة المنتج)
  void _showQuantityDialog() {
  int currentQty = widget.quantity;
  int originalQty = widget.quantity;
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "يرجى تحديد الكمية المتوفرة",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Tajawal",
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (currentQty > 0) {
                          setStateDialog(() => currentQty--);
                        }
                      },
                      icon: const Icon(Icons.remove, color: Colors.black),
                      iconSize: 32,
                    ),

                    const SizedBox(width: 20),

                    Text(
                      "$currentQty",
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: "Tajawal",
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 20),

                    if (currentQty < originalQty)
                      IconButton(
                        onPressed: () {
                          setStateDialog(() => currentQty++);
                        },
                        icon: const Icon(Icons.add, color: Colors.black),
                        iconSize: 32,
                      ),
                  ],
                ),
              ],
            ),

            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Color(0xFF5A9BD5),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),

                        // ⭐ زر موافق
                        onPressed: isLoading
                            ? null
                            : () async {
                                // ⭐ إذا لم تتغير الكمية → لا تفعل شيء
                                if (currentQty == originalQty) {
                                  Navigator.pop(context);
                                  return;
                                }

                                // ⭐ تفعيل التحميل
                                setStateDialog(() => isLoading = true);

                                // ⭐ إرسال الكمية الجديدة
                                await widget.onQuantityChanged(currentQty);

                                // ⭐ إغلاق الديالوغ بعد الانتهاء
                                if (context.mounted) Navigator.pop(context);
                              },

                        child: isLoading
                            ? const LoadingDotsWidget()
                            : const Text(
                                "موافق",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Tajawal",
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Color(0xFFFF0000),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "إلغاء",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Tajawal",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
  String _getOfferDetails(Map<String, dynamic> offer) {
    final offerType = offer['offerType'];

    if (offerType == "DirectDiscount") {
      final price = offer['productDetails']?['price'] ?? 0;
      final discountValue = offer['discountValue'] ?? 0;

      if (price > 0 && discountValue > 0) {
        final percent = ((discountValue / price) * 100).round();
        return "خصم مباشر $percent% ($discountValue ل.س)";
      }

      return "خصم مباشر";
    } else if (offerType == "BuyXGetY") {
      final buyQty = offer['buyQuantity'] ?? 0;
      final getQty = offer['getQuantity'] ?? 0;
      return "اشترِ $buyQty واحصل على $getQty مجاناً";
    } else if (offerType == "FreeItem") {
      final buyQty = offer['buyQuantity'] ?? 1;
      final freeProductName =
          offer['freeProductName'] ??
              offer['productDetails']?['name'] ??
              "منتج";
      return "اشترِ $buyQty واحصل على $freeProductName مجاناً";
    } else {
      return "عرض خاص";
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerType = widget.details['offerType'];

    final productName = widget.details['productDetails']?['name'] ?? "منتج";

    final originalPrice = widget.details['productDetails']?['price'] ?? 0;
    final price = widget.details['price'] ?? originalPrice;
    final discountValue = widget.details['discountValue'] ?? 0;

    int offersCount = widget.quantity;

    int effectiveQuantity;
    if (offerType == "BuyXGetY" || offerType == "FreeItem") {
      int buyQty = widget.details['buyQuantity'] ?? 1;
      effectiveQuantity = buyQty * offersCount;
    } else {
      effectiveQuantity = offersCount;
    }

    final total = (price - discountValue) * effectiveQuantity;
    final offerDetails = _getOfferDetails(widget.details);

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final cardHeight = screenHeight * 0.18;
    final cardWidth = screenWidth * 0.90;

    final imageWidth = cardWidth * 0.35;

    final paddingV = cardHeight * 0.045;
    final paddingH = cardWidth * 0.02;

    final spaceSmall = cardHeight * 0.015;
    final spaceTiny = cardHeight * 0.008;

    final titleFont = screenWidth * 0.04;
    final oldPriceFont = screenWidth * 0.032;
    final priceFont = screenWidth * 0.035;
    final totalFont = screenWidth * 0.038;
    final countFont = screenWidth * 0.03;
    final offerFont = screenWidth * 0.032;

    return Center(
      child: Stack(
        children: [
          Container(
            height: cardHeight,
            width: cardWidth,
            decoration: BoxDecoration(
              color: const Color(0xFFF6FCFC),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: cardHeight * 0.08,
                  offset: Offset(0, cardHeight * 0.02),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: paddingV,
                      horizontal: paddingH,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          offerType == "DirectDiscount"
                              ? "$productName (خصم)"
                              : "$productName (عرض)",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: titleFont,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        SizedBox(height: spaceSmall),

                        if (offerType == "DirectDiscount")
                          Text(
                            "$originalPrice ل.س",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: oldPriceFont,
                              fontFamily: 'Tajawal',
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),

                        SizedBox(height: spaceTiny),

                        Text(
                          offerType == "DirectDiscount"
                              ? "السعر: ${price - discountValue} ل.س × $effectiveQuantity"
                              : "السعر: $price ل.س × $effectiveQuantity",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: priceFont,
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: spaceTiny),

                        Text(
                          "(${total} ل.س)",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: totalFont,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5A9BD5),
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        SizedBox(height: spaceSmall),

                        Text(
                          "عدد العروض المأخوذة: $offersCount",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: countFont,
                            color: Colors.grey,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        Text(
                          offerDetails,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: offerFont,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: cardWidth * 0.02),

                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  child: SizedBox(
                    width: imageWidth,
                    height: cardHeight,
                    child: _imageUrls.isNotEmpty
    ? AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: CachedNetworkImage(
          key: ValueKey<int>(_currentImageIndex),
          imageUrl: ApiConfig.baseUrl + _imageUrls[_currentImageIndex],
          fit: BoxFit.cover,
          width: imageWidth,
          height: cardHeight,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
          ),
          errorWidget: (context, url, error) => Icon(
            Icons.local_offer,
            size: screenWidth * 0.1,
            color: Colors.red,
          ),
        ),
      )
    : Icon(
        Icons.local_offer,
        size: screenWidth * 0.1,
        color: Colors.red,
      ),
                  ),
                ),
              ],
            ),
          ),

          // ⭐ زر تعديل الكمية مثل بطاقة المنتج
         if (widget.canEdit)
  Positioned(
    top: 10,
    left: 10,
    child: GestureDetector(
      onTap: _showQuantityDialog,
      child: Image.asset(
        "assets/images/update.png",
        width: 28,
        height: 28,
      ),
    ),
  ),
        ],
      ),
    );
  }
}