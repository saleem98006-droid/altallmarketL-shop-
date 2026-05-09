import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../widgets/loading_dots_widget.dart'; 

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> details;
  final int quantity;
final bool canEdit;
  // ⭐ إضافة Callback لإرسال الكمية الجديدة للصفحة الأم
  final Function(int newQuantity) onQuantityChanged;

  const ProductCard({
    super.key,
    required this.details,
    required this.quantity,
    required this.canEdit,
    required this.onQuantityChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _currentImageIndex = 0;
  late List<String> _imageUrls;
  @override
  void initState() {
    super.initState();

   _imageUrls = [
  widget.details['imageUrl1'],
  widget.details['imageUrl2'],
  widget.details['imageUrl3'],
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

  // ⭐ الديالوغ الخاص بتحديد الكمية
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

  @override
  Widget build(BuildContext context) {
    final price = widget.details['price'] ?? 0;
    final total = price * widget.quantity;

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final cardHeight = screenHeight * 0.13;
    final cardWidth = screenWidth * 0.90;
    final imageWidth = cardWidth * 0.35;

    final paddingV = cardHeight * 0.045;
    final paddingH = cardWidth * 0.02;

    final spaceSmall = cardHeight * 0.015;
    final spaceTiny = cardHeight * 0.008;

    final titleFont = screenWidth * 0.04;
    final normalFont = screenWidth * 0.033;
    final totalFont = screenWidth * 0.038;

    return Center(
      child: Stack(
        children: [
          Container(
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
  child: IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // النصوص
        Expanded(
          flex: 65,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: paddingV,
              horizontal: paddingH,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.details['name'] ?? "منتج",
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: titleFont,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                SizedBox(height: spaceSmall),
                Text(
                  "الكمية: ${widget.quantity}",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: normalFont,
                    fontFamily: 'Tajawal',
                  ),
                ),
                SizedBox(height: spaceTiny),
                Text(
                  "السعر: $price ل.س",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: normalFont,
                    fontFamily: 'Tajawal',
                  ),
                ),
                SizedBox(height: spaceTiny),
                Text(
                  "الإجمالي: $total ل.س",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: totalFont,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5A9BD5),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: cardWidth * 0.02),

        // الصورة
        ClipRRect(
  borderRadius: const BorderRadius.only(
    topRight: Radius.circular(25),
    bottomRight: Radius.circular(25),
  ),
  child: SizedBox(
    width: imageWidth,
    height: double.infinity, // ⭐ الآن الصورة تملأ البطاقة
    child: _imageUrls.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: ApiConfig.baseUrl + _imageUrls[_currentImageIndex],
            fit: BoxFit.cover,
          )
        : Icon(
            Icons.image_not_supported,
            size: screenWidth * 0.1,
            color: Colors.grey,
          ),
  ),
),
      ],
    ),
  ),
),

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