import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../snackBar/snackbar.dart';
import '../../core/app_events.dart';
import '../../widgets/loading_dots_widget.dart';

class AddDiscountScreen extends StatefulWidget {
  const AddDiscountScreen({super.key}); // ❌ حذفنا productId و productName

  @override
  State<AddDiscountScreen> createState() => _AddDiscountScreenState();
}

class _AddDiscountScreenState extends State<AddDiscountScreen> {
  final TextEditingController discountController = TextEditingController();
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();



  List<Map<String, dynamic>> products = [];
  int? selectedProductId;
  String? selectedProductName;
  double? productPrice;
  double discountPercent = 0;

  DateTime? startDate;
  DateTime? endDate;

  // 🆕 متغيرات الإشعار
  bool notify = false;
  bool notifyAlreadySent = false;
  int? shopId;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    shopId = prefs.getInt('shopId') ?? 0;

    final result = await ApiService.getProductsByShop(shopId!);
    if (result != null) {
      setState(() {
        products = result;
      });
    }
  }

  Future<void> _loadProductPrice(int productId) async {
    final result = await ApiService.getProductPrice(productId);
    if (result != null && result['price'] != null) {
      setState(() {
        productPrice = double.tryParse(result['price'].toString());
      });
    }
  }

  void _calculatePercent(String value) {
    final discountValue = double.tryParse(value) ?? 0;
    if (productPrice != null && productPrice! > 0) {
      setState(() {
        discountPercent = (discountValue / productPrice!) * 100;
      });
    }
  }

  Future<void> _selectDiscountDateTime(bool isStart) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final DateTime fullDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      int hour = pickedTime.hourOfPeriod;
      if (hour == 0) hour = 12;
      String period = pickedTime.period == DayPeriod.am ? "AM" : "PM";

      final String formatted =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
          "${hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')} $period";

      setState(() {
        if (isStart) {
          _startDateController.text = formatted;
          startDate = fullDateTime;
        } else {
          _endDateController.text = formatted;
          endDate = fullDateTime;
        }
      });
    }
  }
}


  

 Future<void> _saveDiscount() async {
  setState(() => isSaving = true); // 🔥 بدء التحميل

  if (selectedProductId == null) {
    snackBar(context, "يجب اختيار منتج");
    setState(() => isSaving = false);
    return;
  }

  if (discountController.text.isEmpty || startDate == null || endDate == null) {
    snackBar(context, "يرجى ادخال جميع البيانات");
    setState(() => isSaving = false);
    return;
  }

  final discountValue = double.tryParse(discountController.text) ?? 0;

  final discountData = {
    "productId": selectedProductId,
    "discountValue": discountValue,
    "startDate": startDate!.toIso8601String(),
    "endDate": endDate!.toIso8601String(),
  };

  try {
    final result = await ApiService.addDiscount(discountData);

    if (result != null && result['success'] == true) {
      final discountId = result['discountId'] ?? result['offerId'];
      String dialogMessage = "";

      // -----------------------------
      // ✔ حالة بدون إشعار
      // -----------------------------
      if (!notify) {
        snackBar(context, "تمت إضافة الخصم بنجاح");
        //AppEvents().emit("refresh_home");
         AppEvents().emit("refresh_offers");
        setState(() => isSaving = false); // 🔥 إيقاف التحميل
        Navigator.pop(context);
        return;
      }

      // -----------------------------
      // ✔ حالة مع إشعار
      // -----------------------------
      if (discountId != null) {
        final prefs = await SharedPreferences.getInstance();
        final areaId = prefs.getInt('areaID') ?? prefs.getInt('areaId') ?? 0;

        print("Selected Product ID = $selectedProductId");
        final notifyResult = await ApiService.sendAndDistribute(
          context,
          shopId!,
          {
            "contextType": "Discount",
            "discountTitle": "خصم جديد",
            "senderId": shopId,
            "areaId": areaId,
            "relatedEntity": "Offer",
            "relatedId": selectedProductId,
          },
        );

        if (notifyResult != null && notifyResult['success'] == true) {
          dialogMessage =
              "تمت إضافة الخصم بنجاح\nوتم إرسال الإشعار لجميع الزبائن";
        } else if (notifyResult != null && notifyResult['success'] == false) {
          dialogMessage =
              "لقد تجاوزت الحد المسموح به للإشعارات\nلن يتم إرسال إشعار جديد\n-------------------------\nتمت إضافة الخصم بنجاح";
        } else {
          dialogMessage = "تمت إضافة الخصم بنجاح";
        }
      } else {
        dialogMessage = "تمت إضافة الخصم بنجاح";
      }

      setState(() => isSaving = false); // 🔥 إيقاف التحميل قبل عرض الديالوغ

      // -----------------------------
      // ✔ نافذة النجاح بتصميم جديد
      // -----------------------------
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          Future.delayed(const Duration(seconds: 3), () {
            Navigator.of(ctx).pop();
            //AppEvents().emit("refresh_home");
             AppEvents().emit("refresh_offers");
            Navigator.pop(context);
          });

          return WillPopScope(
            onWillPop: () async => false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                content: Text(
                  dialogMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      );

    } else {
      snackBar(context, "فشل في إضافة الخصم");
      setState(() => isSaving = false);
    }
  } catch (e) {
    print("Exception أثناء إضافة الخصم: $e");
    snackBar(context, "حدث خطأ غير متوقع أثناء إضافة الخصم");
    setState(() => isSaving = false);
  }
}


void _showProductBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40)), // انحناء أكبر
    ),
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [

                

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: products.map((p) {
                      return ListTile(
                        title: Text(
                          p['productName'],
                          style: const TextStyle(
                            fontSize: 16,          // تكبير الخط
                            //fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedProductId = p['productId'];
                            selectedProductName = p['productName'];
                            _loadProductPrice(p['productId']);
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
       
      );
    },
  );
}



 @override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
     // 🔥 الأزرار المثبتة بالأسفل
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر إرسال إشعار
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: notify ? Color(0xFF5A9BD5) : Colors.white,
                side: const BorderSide(color: Color(0xFF5A9BD5), width: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                setState(() {
                  notify = !notify; // ← نفس عمل السويتش
                });
              },
              child: Text(
                "إرسال إشعار",
                style: TextStyle(
                  color: notify ? Colors.white : Colors.black,
                   fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Tajawal',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

         // زر إضافة
SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    onPressed: isSaving ? null : _saveDiscount,
    child: isSaving
        ? const LoadingDotsWidget()
        : const Text(
            "إضافة",
            style: TextStyle(fontFamily: "Tajawal"),
          ),
  ),
),



        ],
      ),
    ),
   body: Stack(
  fit: StackFit.expand,
  children: [
    SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.05),

            // 🔹 عنوان الصفحة
            const Text(
              "إضافة خصم",
              style: TextStyle(
                fontSize: 24,
                //fontWeight: FontWeight.bold,
                fontFamily: "Tajawal",
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: screenHeight * 0.05),

            // 🔹 اختيار المنتج عبر BottomSheet
            Directionality(
              textDirection: TextDirection.rtl,
              child: InkWell(
                onTap: _showProductBottomSheet,
                child: IgnorePointer(
                  child: TextField(
                    readOnly: true,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: selectedProductId == null
                          ? "اختر منتج"
                          : selectedProductName,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: "Tajawal",
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(0xFF5A9BD5),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(0xFF5A9BD5),
                          width: 2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF5A9BD5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (productPrice != null)
             Padding(
  padding: EdgeInsets.only(
    right: MediaQuery.of(context).size.width * 0.05, // 👈 5% من عرض الشاشة
  ),
  child: Align(
    alignment: Alignment.centerRight,
    child: Text(
      "السعر: ${productPrice!.toStringAsFixed(2)} ل.س",
      textAlign: TextAlign.right,
    ),
  ),
),


            const SizedBox(height: 10),

            // 🔹 قيمة الخصم
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: "قيمة الخصم",
                  border: OutlineInputBorder(),
                ),
                onChanged: _calculatePercent,
              ),
            ),

            const SizedBox(height: 20),

            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                    right: MediaQuery.of(context).size.width * 0.04),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text("${discountPercent.toStringAsFixed(2)} %"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 تاريخ البداية
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _startDateController,
                readOnly: true,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: "تاريخ البداية",
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDiscountDateTime(true),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 تاريخ النهاية
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _endDateController,
                readOnly: true,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: "تاريخ النهاية",
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDiscountDateTime(false),
              ),
            ),

            const SizedBox(height: 20),

            

            const SizedBox(height: 120), // مساحة للأزرار المثبتة
          ],
        ),
      ),
    ),
  ],
),

  );
}

}
