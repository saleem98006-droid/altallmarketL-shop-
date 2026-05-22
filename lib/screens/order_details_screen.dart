import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'shop_order_items_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'snackBar/snackbar.dart';
import '../core/app_events.dart';
import '../widgets/loading_dots_widget.dart';

class OrderDetailsScreen extends StatefulWidget {
 /* final int shopOrderID;
final double subTotal;
final String statusSource;

final String customerName;
final String customerNote;
final int totalItems;

OrderDetailsScreen({
  super.key,
  required this.shopOrderID,
  required this.subTotal,
  required this.statusSource,
  required this.customerName,
  required this.customerNote,
  required this.totalItems,
});*/
final int shopOrderID;
final int? unifiedOrderID;
  final double subTotal;
  final String statusSource;
  final String? customerPhone;

  final String? customerName;
  final String? customerNote;
  final int? totalItems;
  final bool? withoutDelivery;


  const OrderDetailsScreen({
    super.key,
    required this.shopOrderID,
    required this.subTotal,
    required this.statusSource,
    this.customerName,
    this.customerNote,
    this.customerPhone,
    this.totalItems,
    this.withoutDelivery,
    this.unifiedOrderID,
  });


  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List items = [];
  String customerNote = '';
  String customerName = '';
  late double subTotal;
  bool isLoading = true;
   bool showContactCard = false;
   bool isAcceptLoading = false;
bool isDeliverLoading = false;
bool isRejectLoading = false;
bool canEdit = false;

  Widget _buildLoadingShimmer() {
    Widget line(double width, {double height = 12}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                line(170, height: 20),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: line(130, height: 16),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, __) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6FCFC),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            line(120),
                            const SizedBox(height: 10),
                            line(double.infinity),
                            const SizedBox(height: 8),
                            line(180),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: line(double.infinity, height: 44)),
                    const SizedBox(width: 12),
                    Expanded(child: line(double.infinity, height: 44)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔵 كاش تفاصيل عناصر الطلب حسب shopOrderID
  static final Map<int, List<dynamic>> _orderItemsCache = {};

  @override
  void initState() {
    super.initState();
    subTotal = widget.subTotal;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    if (_orderItemsCache.containsKey(widget.shopOrderID)) {
      setState(() {
        items = List<dynamic>.from(_orderItemsCache[widget.shopOrderID]!);
        canEdit = (
          widget.statusSource != "مكتمل" &&
          widget.statusSource != "ملغي" &&
          widget.statusSource != "جاهز للتوصيل" &&
          widget.statusSource != "جديد"
        );
        isLoading = false;
      });
      return;
    }

  final response = await ApiService.getShopOrderItemsByShopOrder(
    shopOrderId: widget.shopOrderID,
  );

  if (!mounted) return;

  if (response != null && response['success'] == true) {
    
    setState(() {
      items = response['items'];   // ← هنا تأتي items
     
  // ⭐ تحديد هل الطلب قابل للتعديل
 canEdit = (
  widget.statusSource != "مكتمل" &&
  widget.statusSource != "ملغي" &&
  widget.statusSource != "جاهز للتوصيل"&&
  widget.statusSource != "جديد"
);

      isLoading = false;

      _orderItemsCache[widget.shopOrderID] = List<dynamic>.from(items);
    });
  } else {
    setState(() => isLoading = false);
  }
}

Future<void> _updateItemQuantity(int shopOrderItemId, int newQty) async {
  setState(() => isLoading = true);

  final response = await ApiService.updateShopOrderItemQuantity(
    shopOrderItemId,
    newQty,
  );

  if (!mounted) return;

  setState(() => isLoading = false);

  if (response == null || response['success'] != true) {
    snackBar(context, "فشل تعديل الكمية");
    return;
  }

  // إذا تم حذف طلب المحل بالكامل → اخرج من الصفحة
  if (response['ShopOrderDeleted'] == true || response['shopOrderDeleted'] == true) {
    _orderItemsCache.remove(widget.shopOrderID);
    snackBar(context, "تم حذف طلب المحل بالكامل");
    Navigator.pop(context);
    return;
  }

  // تحديث العناصر
  if (response['Items'] != null && response['Items'] is List) {
    setState(() {
      items = response['Items'];
      _orderItemsCache[widget.shopOrderID] = List<dynamic>.from(items);
    });
  } else if (response['items'] != null && response['items'] is List) {
    setState(() {
      items = response['items'];
      _orderItemsCache[widget.shopOrderID] = List<dynamic>.from(items);
    });
  }

  // تحديث SubTotal
  if (response['SubTotal'] != null) {
    setState(() {
      subTotal = (response['SubTotal'] as num).toDouble();
    });
  } else if (response['subTotal'] != null) {
    setState(() {
      subTotal = (response['subTotal'] as num).toDouble();
    });
  } else if (response['TotalAmount'] != null) {
    setState(() {
      subTotal = (response['TotalAmount'] as num).toDouble();
    });
  }

  snackBar(context, "تم تعديل الكمية بنجاح");
}

 Future<void> _updateStatus(String status) async {
  final prefs = await SharedPreferences.getInstance();
  int? areaId = prefs.getInt('areaID');
  areaId ??= int.tryParse((prefs.getString('areaID') ?? '').trim());
  if (areaId == null || areaId <= 0) {
    snackBar(context, "تعذر قراءة المنطقة، أعد تسجيل الدخول");
    return;
  }

  // تشغيل حالة التحميل حسب نوع الزر
  setState(() {
    if (status == "قيد التعبئة") {
      isAcceptLoading = true;
    } else if (status == "جاهز للتوصيل" || status == "مكتمل") {
      isDeliverLoading = true;
    } else if (status == "ملغي") {
      isRejectLoading = true;
    }
  });

  // استدعاء API
  final result = await ApiService.updateOrderStatus(
    widget.shopOrderID,
    status,
    areaId,
  );
 
  if (!mounted) return;

  // إيقاف التحميل
  setState(() {
    isAcceptLoading = false;
    isDeliverLoading = false;
    isRejectLoading = false;
  });

  // التحقق من النجاح
  if (result != null && result['success'] == true) {
    snackBar(context, "تم تحديث حالة الطلب إلى $status");
AppEvents().emit("refresh_orders");

    // ⭐ الرجوع دائمًا عند النجاح
    Navigator.pop(context);

  } else {
    snackBar(context, "فشل في تحديث حالة الطلب");
  }
}

 void _showCancelReasonDialog() {
  final TextEditingController reasonController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // ⭐ انحناء 50
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "الرجاء إدخال سبب الرفض",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "اكتب السبب هنا...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // زر إلغاء
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // ⭐ انحناء 20
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          "إلغاء",
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Tajawal",
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // زر رفض (مع تحميل)
                      OutlinedButton(
                        onPressed: isRejectLoading
                            ? null
                            : () async {
                                final reason = reasonController.text.trim();
                                if (reason.isEmpty) {
                                  snackBar(context, "يرجى كتابة سبب الرفض");
                                  return;
                                }

                                setStateDialog(() {
                                  isRejectLoading = true;
                                });

                                final noteResult =
                                    await ApiService.updateShopNotes(
                                        widget.shopOrderID, reason);

                                if (noteResult != null &&
                                    noteResult['success'] == true) {
                                  await _updateStatus("ملغي");
                                  if (mounted) Navigator.pop(context);
                                } else {
                                  snackBar(context, "فشل في حفظ سبب الرفض");
                                }

                                setStateDialog(() {
                                  isRejectLoading = false;
                                });
                              },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // ⭐ انحناء 20
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: isRejectLoading
                            ? const LoadingDotsWidget(color: Colors.red)
                            : const Text(
                                "رفض",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: "Tajawal",
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}




@override
Widget build(BuildContext context) {
  if (isLoading) {
    return _buildLoadingShimmer();
  }

  if (items.isEmpty) {
    return const Scaffold(
      body: Center(child: Text("❌ لم يتم العثور على تفاصيل لهذا الطلب")),
    );
  }

  return Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      // رقم الطلب
                      Center(
                        child: Text(
                         // "الطلب: ${widget.shopOrderID}",
                          "الطلب: ${widget.unifiedOrderID}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Tajawal",
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // اسم الزبون (قابل للضغط)
                      Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [

    // 👈 اسم الزبون فقط هو القابل للضغط
    GestureDetector(
      onTap: () {
        setState(() {
          showContactCard = !showContactCard;
        });
      },
      child: Text(
        widget.customerName ?? "غير معروف",
        style: const TextStyle(
          fontSize: 18,
          fontFamily: "Tajawal",
          color: Color(0xFF5A9BD5),
          decoration: TextDecoration.underline,
        ),
      ),
    ),

    const SizedBox(width: 6),

    // 👈 كلمة "الزبون:" ثابتة وغير قابلة للضغط
    const Text(
      "الزبون",
      style: TextStyle(
        fontSize: 18,
        fontFamily: "Tajawal",
        color: Colors.black,
      ),
    ),
  ],
),

                      const SizedBox(height: 8),

                      // المنتجات
                    ShopOrderItemsList(
  items: items,
  onQuantityChanged: _updateItemQuantity,
    canEdit: canEdit,
),

                      const SizedBox(height: 20),

                      // ملاحظة الزبون
                      if ((widget.customerNote ?? "").isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Color(0xFF5A9BD5), width: 2),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "ملاحظة الزبون",
                                style: TextStyle(
                                  fontFamily: "Tajawal",
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5A9BD5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.customerNote!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontFamily: "Tajawal",
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // الأزرار
              if (widget.statusSource == "جديد")
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Row(
                    children: [

                       Expanded(
                        child: OutlinedButton(
                          onPressed: _showCancelReasonDialog,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 2),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "رفض",
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: "Tajawal",
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
 const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus("قيد التعبئة"),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                                                  child: isAcceptLoading
                                ? const LoadingDotsWidget()
                                : const Text(
                                    "قبول",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: "Tajawal",
                                      fontSize: 16,
                                    ),
                                  ),
                                                    ),
                                                  ),
                     
                     
                    ],
                  ),
                )
              else if (widget.statusSource == "قيد التعبئة")
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                     Align(
  alignment: Alignment.centerRight,
  child: Text(
    "إجمالي الطلب: ${subTotal.toStringAsFixed(2)} ل.س",
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: "Tajawal",
    ),
  ),
),
                      const SizedBox(height: 12),
                      OutlinedButton(
                       onPressed: () {
  final newStatus = (widget.withoutDelivery  == true)
      ? "مكتمل"
      : "جاهز للتوصيل";

  _updateStatus(newStatus);
},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
                          backgroundColor: Colors.white, 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: isDeliverLoading
    ? const LoadingDotsWidget()
    : const Text(
        "تسليم",
        style: TextStyle(
          color: Colors.black,
          fontFamily: "Tajawal",
          fontSize: 16,
        ),
      ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // ✅ البطاقة العائمة فوق الشاشة
          if (showContactCard)
  Positioned(
    top: 90,
    right: 20,
    child: Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF6FCFC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // 🔥 زر الاتصال
            InkWell(
              onTap: () {
                _callCustomer();   // ← استدعاء دالة الاتصال
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/phone1.png",
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "اتصال",
                    style: TextStyle(fontFamily: "Tajawal"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 زر المراسلة
            InkWell(
              onTap: () {
                _openWhatsApp();   // ← استدعاء دالة الواتساب
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/whatsapp.png",
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "مراسلة",
                    style: TextStyle(fontFamily: "Tajawal"),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    ),
  ),
        ],
      ),
    ),
  );
}

Future<void> _callCustomer() async {
  final phone = (widget.customerPhone ?? "").trim();

  if (phone.isEmpty) return;

  final uri = Uri(scheme: "tel", path: phone);

  if (!await launchUrl(uri)) {
    if (mounted) {
    
      snackBar(context, " تعذر فتح تطبيق الهاتف");
    }
  }
}

Future<void> _openWhatsApp() async {
  final phone = (widget.customerPhone ?? "").replaceAll("+", "").trim();

  if (phone.isEmpty) return;

  final link = "https://wa.me/$phone";

  final ok = await launchUrlString(
    link,
    mode: LaunchMode.externalApplication,
  );

  if (!ok && mounted) {
   
     snackBar(context, "تعذر فتح واتساب");
  }
}
}