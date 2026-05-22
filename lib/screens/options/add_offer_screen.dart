import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../snackBar/snackbar.dart';
import '../../core/app_events.dart';
import '../../widgets/loading_dots_widget.dart';

class AddOfferScreen extends StatefulWidget {
  const AddOfferScreen({super.key});

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  static const Color kBlue = Color(0xFF5a9bd5);

  Map<String, dynamic>? selectedProduct;
  Map<String, dynamic>? otherProduct;
  int offerType = -1; // 0: BuyXGetY, 1: FreeItem

  final TextEditingController _buyCountController = TextEditingController();
  final TextEditingController _getCountController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _otherProductController = TextEditingController();
 



  List<Map<String, dynamic>> products = [];
  int? shopId;

  // متغيرات الإشعار
  bool notify = false;
  bool notifyAlreadySent = false;
  bool _productFieldActive = false;
DateTime? _startDateValue;
DateTime? _endDateValue;
bool isSaving = false;


  @override
  void initState() {
    super.initState();
    _initShopAndProducts();
  }

  Future<void> _initShopAndProducts() async {
    final prefs = await SharedPreferences.getInstance();
    shopId = prefs.getInt('shopId') ?? 0;
    if (shopId != 0) {
      await _loadProducts(shopId!);
    }
  }

  Future<void> _loadProducts(int shopId) async {
    final result = await ApiService.getProductsByShop(shopId);
    if (result != null) {
      setState(() {
        products = result;
      });
    }
  }

 Future<void> _selectDateTime(
    BuildContext context, TextEditingController controller) async {
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
        controller.text = formatted;

        if (controller == _startDateController) {
          _startDateValue = fullDateTime;
        } else if (controller == _endDateController) {
          _endDateValue = fullDateTime;
        }
      });
    }
  }
}




  

 

  

 






  Future<void> _saveOffer() async {
  setState(() => isSaving = true); // 🔥 بدء التحميل

  if (selectedProduct == null) {
    snackBar(context, "يجب اختيار منتج");
    setState(() => isSaving = false);
    return;
  }

  if (offerType == -1) {
    snackBar(context, "يرجى اختيار نوع العرض");
    setState(() => isSaving = false);
    return;
  }

  if (_buyCountController.text.isEmpty ||
      _startDateController.text.isEmpty ||
      _endDateController.text.isEmpty ||
      (offerType == 0 && _getCountController.text.isEmpty) ||
      (offerType == 1 && otherProduct == null)) {
    snackBar(context, "يرجى ادخال جميع البيانات");
    setState(() => isSaving = false);
    return;
  }

  final DateTime? startDate = _startDateValue;
  final DateTime? endDate = _endDateValue;

  if (startDate == null || endDate == null) {
    snackBar(context, "صيغة التاريخ غير صحيحة");
    setState(() => isSaving = false);
    return;
  }

  String offerTypeStr = offerType == 0 ? "BuyXGetY" : "FreeItem";

  final data = {
    "productId": selectedProduct!['productId'],
    "offerType": offerTypeStr,
    "buyQuantity": int.tryParse(_buyCountController.text) ?? 0,
    "getQuantity": offerType == 0
        ? (int.tryParse(_getCountController.text) ?? 0)
        : 1,
    "freeProductId": offerType == 1 && otherProduct != null
        ? otherProduct!['productId']
        : null,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
  };

  try {
    final result = await ApiService.addOffer(data);

    if (result != null && result['success'] == true) {
      final offerId = result['offerId'];
      String dialogMessage = "";

      // حالة بدون إشعار
      if (!notify) {
        snackBar(context, "تمت إضافة العرض بنجاح");
       // AppEvents().emit("refresh_home");
        AppEvents().emit("refresh_offers");
        setState(() => isSaving = false);
        Navigator.pop(context);
        return;
      }
final int mainProductId = selectedProduct!['productId'];
      // حالة مع إشعار
      if (offerId != null) {
        final prefs = await SharedPreferences.getInstance();
        final areaId = prefs.getInt('areaID') ?? prefs.getInt('areaId') ?? 0;

        final notifyResult = await ApiService.sendAndDistribute(
          context,
          shopId!,
          {
            "contextType": "Offer",
            "offerTitle": "عرض جديد",
            "senderId": shopId,
            "areaId": areaId,
            "relatedEntity": "Offer",
            "relatedId": mainProductId,

          },
        );

        if (notifyResult != null && notifyResult['success'] == true) {
          dialogMessage =
              "تمت إضافة العرض بنجاح\nوتم إرسال الإشعار لجميع الزبائن";
        } else if (notifyResult != null && notifyResult['success'] == false) {
          dialogMessage =
              "لقد تجاوزت الحد المسموح به للإشعارات\nلن يتم إرسال إشعار جديد\n-------------------------\nتمت إضافة العرض بنجاح";
        } else {
          dialogMessage = "تمت إضافة العرض بنجاح";
        }
      } else {
        dialogMessage = "تمت إضافة العرض بنجاح";
      }

      setState(() => isSaving = false); // 🔥 إيقاف التحميل قبل عرض الديالوغ

      // نافذة النجاح بتصميم جديد
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
      snackBar(context, "❌ فشل في إضافة العرض");
      setState(() => isSaving = false);
    }
  } catch (e) {
    print("❌ Exception أثناء إضافة العرض: $e");
    snackBar(context, "حدث خطأ غير متوقع أثناء إضافة العرض");
    setState(() => isSaving = false);
  }
}


  @override
  Widget build(BuildContext context) {
     final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
       backgroundColor: Colors.white, // ← الخلفية بيضاء فقط

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
    onPressed: isSaving ? null : _saveOffer,
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
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    Center(
                      child: Text(
                        "إضافة عرض",
                        style: TextStyle(
                          fontSize: 24,
                           fontFamily: "Tajawal",
                          //fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                 InkWell(
  onTap: () async {
    setState(() => _productFieldActive = true);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: products.map((p) {
              return ListTile(
                title: Text(p['productName']),
                onTap: () {
                  setState(() {
                    selectedProduct = p;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    setState(() => _productFieldActive = false);
  },
  child: AbsorbPointer(
    child: TextField(
      readOnly: true,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: selectedProduct == null
            ? "اختر منتج"
            : selectedProduct!['productName'],   // ← هنا يظهر اسم المنتج المختار
        labelStyle: const TextStyle(fontSize: 16),

        // البوردر العادي
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: kBlue,
            width: _productFieldActive ? 3 : 2,
          ),
        ),

        // عند الضغط
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Color(0xFF5A9BD5),
            width: _productFieldActive ? 3 : 2,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Color(0xFF5A9BD5),
            width: _productFieldActive ? 3 : 2,
          ),
        ),
      ),
    ),
  ),
),

                    const SizedBox(height: 20),

                   
                    // نوع العرض
                    Padding(
  padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.05),
  child: const Text(
    "نوع العرض",
    style: TextStyle(fontSize: 18),
  ),
),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text("من نفس المنتج"),
                            value: 0,
                            groupValue: offerType,
                            activeColor: kBlue,
                            onChanged: (val) {
                              setState(() {
                                offerType = val!;
                                otherProduct = null; // إعادة التهيئة
                              });
                            },
                          ),
                        ),
                       Expanded(
  child: RadioListTile<int>(
    title: const Text("منتج آخر"),
    value: 1,
    groupValue: offerType,
    activeColor: kBlue,
    onChanged: (val) async {
      setState(() {
        offerType = val!;
      });

      if (offerType == 1) {
        await _pickProduct((p) {
          setState(() {
            otherProduct = p;
            _otherProductController.text = p['productName'];
          });
        });
      }
    },
  ),
),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 🔹 الحقول حسب نوع العرض
                    if (offerType == 0) ...[
                      // من نفس المنتج
                      Row(
                        children: [
                         
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
  controller: _buyCountController,
  keyboardType: TextInputType.number,
  textAlign: TextAlign.right,
  decoration: const InputDecoration(
    labelText: "اشترِ عدد",
  ),
),


                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                         
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
  controller: _getCountController,
  keyboardType: TextInputType.number,
  textAlign: TextAlign.right,
  decoration: const InputDecoration(
    labelText: "احصل على عدد",
  ),
),

                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ] else if (offerType == 1) ...[
                      // منتج آخر
                      Row(
                        children: [
                          
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
  controller: _buyCountController,
  keyboardType: TextInputType.number,
  textAlign: TextAlign.right,
  decoration: const InputDecoration(
    labelText: "اشترِ عدد",
  ),
),

                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
  child: InkWell(
    onTap: () async {
  await _pickProduct((p) {
    setState(() {
      otherProduct = p;
      _otherProductController.text = p['productName'];
    });
  });
},
    child: IgnorePointer(
      child: TextField(
  controller: _otherProductController,
  readOnly: true,
  textAlign: TextAlign.right,
  decoration: const InputDecoration(
    labelText: "احصل على",
  ),
),

    ),
  ),
),

                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // اختيار التاريخ والوقت
                    TextField(
  controller: _startDateController,
  readOnly: true,
  textAlign: TextAlign.right,
  decoration: const InputDecoration(
    labelText: "تاريخ البداية",
  ),
  onTap: () => _selectDateTime(context, _startDateController),
),

                    const SizedBox(height: 16),

                   TextField(
  controller: _endDateController,
  readOnly: true,
  textAlign: TextAlign.right,
  decoration: const InputDecoration(
    labelText: "تاريخ النهاية",
  ),
  onTap: () => _selectDateTime(context, _endDateController),
),

                   const SizedBox(height: 120), // مساحة للأزرار المثبتة
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _pickProduct(void Function(Map<String, dynamic>) onSelected) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
    ),
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: products.map((p) {
            return ListTile(
              title: Text(p['productName']),
              onTap: () {
                onSelected(p);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      );
    },
  );
}
}

