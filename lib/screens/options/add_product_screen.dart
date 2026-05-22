import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../snackBar/snackbar.dart';
import '../../core/app_events.dart';
import '../../utils/image_compressor.dart';
import '../../widgets/loading_dots_widget.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const Color kBlue = Color(0xFF5a9bd5);

  final ImagePicker _picker = ImagePicker();
  List<File?> selectedImages = [null, null, null];

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _priceUsdController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // FocusNodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final FocusNode _priceUsdFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  bool _isDollarEnabled = false;

  // 🟢 فقط سويتش الإشعار
  bool notify = false;
  bool isSaving = false;
  final Uuid _uuid = const Uuid();
  static const Duration _idempotencyWindow = Duration(minutes: 2);
  String? _lastSubmissionFingerprint;
  String? _lastIdempotencyKey;
  DateTime? _lastSubmissionAt;


  // 🆕 التصنيفات
  List<dynamic> sections = [];
  int? selectedSectionId;
  String? selectedSectionName;

  @override
  void initState() {
    super.initState();
    _loadShopCurrencySettings();
  }

  Future<void> _loadShopCurrencySettings() async {
    final prefs = await SharedPreferences.getInstance();

    bool isDollarEnabled = prefs.getBool('isDollarEnabled') ?? false;
    final shopId = prefs.getInt('shopId') ?? 0;

    // ✅ إذا لم تكن القيمة محفوظة/محدّثة محلياً، نجلبها من السيرفر
    if (shopId > 0) {
      final shopData = await ApiService.getShopById(shopId);
      if (shopData != null) {
        if (shopData.containsKey('isDollarEnabled') ||
            shopData.containsKey('IsDollarEnabled')) {
          final rawDollar =
              shopData['isDollarEnabled'] ?? shopData['IsDollarEnabled'];
          isDollarEnabled = rawDollar == true ||
              rawDollar.toString().trim().toLowerCase() == 'true' ||
              rawDollar.toString().trim() == '1';
          await prefs.setBool('isDollarEnabled', isDollarEnabled);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _isDollarEnabled = isDollarEnabled;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _priceUsdController.dispose();
    _descController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    _priceUsdFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImages[index] = File(image.path);
      });
    }
  }

  String? _encodeImage(File? file) {
    if (file == null) return null;
    try {
      final bytes = file.readAsBytesSync();
      return base64Encode(bytes);
    } catch (e) {
      print("❌ خطأ في قراءة الصورة: $e");
      return null;
    }
  }

  // 🆕 جلب التصنيفات
  Future<void> _fetchSections() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt("shopId");
    if (shopId == null) return;

    final result = await ApiService.getSectionsByShop(shopId);
    if (result != null && result["success"] == true) {
      setState(() {
        sections = result["sections"];
      });
    }
  }

  // 🆕 نافذة اختيار التصنيف
  void _showSectionDialog() async {
  await _fetchSections();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white, // ✅ خلفية بيضاء
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // ✅ انحناء 40
        ),
        title: const Center(
          child: Text(
            "اختر التصنيف",
            style: TextStyle(
              fontSize: 20,
              fontFamily: "Tajawal",
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        content: sections.isEmpty
            ? const Text("لا يوجد تصنيفات")
            : SizedBox(
                width: double.maxFinite,
                child: Directionality(
                  textDirection: TextDirection.rtl, // ✅ الخيارات من اليمين
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      final id = section["sectionId"];
                      final name = section["sectionName"];
                   return RadioListTile<int>(
  title: Text(
    name,
    style: const TextStyle(fontFamily: "Tajawal"),
  ),
  value: id,
  groupValue: selectedSectionId,
  activeColor: const Color(0xFF5A9BD5), // ✅ الدائرة تصبح زرقاء عند الاختيار
  onChanged: (val) {
    setState(() {
      selectedSectionId = val;
      selectedSectionName = name;
    });
    Navigator.pop(context);
  },
);
                    },
                  ),
                ),
              ),
      );
    },
  );
}
  
 
Future<void> _saveProduct() async {
  if (isSaving) return;
  setState(() => isSaving = true);

  final prefs = await SharedPreferences.getInstance();
  final shopId = prefs.getInt('shopId') ?? 0;
  final areaId = prefs.getInt('areaID') ?? prefs.getInt('areaId') ?? 0;
  final isDollarEnabled = prefs.getBool('isDollarEnabled') ?? _isDollarEnabled;

  if (shopId == 0) {
    snackBar(context, "لا يوجد انترنت اعد المحاولة");
    setState(() => isSaving = false);
    return;
  }

  if (selectedSectionId == null || selectedSectionId == 0) {
    snackBar(context, "يجب اختيار تصنيف");
    setState(() => isSaving = false);
    return;
  }

  final String sypText = _priceController.text.trim();
  final String usdText = _priceUsdController.text.trim();

  final double? priceSyp = sypText.isEmpty ? null : double.tryParse(sypText);
  final double? priceUsd = usdText.isEmpty ? null : double.tryParse(usdText);

  if (isDollarEnabled) {
    if (priceSyp == null && priceUsd == null) {
      snackBar(context, "يجب إدخال سعر واحد على الأقل (سوري أو دولار)");
      setState(() => isSaving = false);
      return;
    }
  } else {
    if (priceSyp == null || priceSyp <= 0) {
      snackBar(context, "الرجاء إدخال السعر بالليرة السورية بشكل صحيح");
      setState(() => isSaving = false);
      return;
    }
  }

  if (priceSyp != null && priceSyp <= 0) {
    snackBar(context, "السعر بالليرة يجب أن يكون أكبر من الصفر");
    setState(() => isSaving = false);
    return;
  }

  if (priceUsd != null && priceUsd <= 0) {
    snackBar(context, "السعر بالدولار يجب أن يكون أكبر من الصفر");
    setState(() => isSaving = false);
    return;
  }

final compressedImage1 = await ImageCompressor.compressFile(selectedImages[0]);
final compressedImage2 = await ImageCompressor.compressFile(selectedImages[1]);
final compressedImage3 = await ImageCompressor.compressFile(selectedImages[2]);

  final imagePaths = selectedImages
      .map((f) => f?.path ?? '')
      .join('|');
  final submissionFingerprint = [
    shopId,
    _nameController.text.trim(),
    _descController.text.trim(),
    _priceController.text.trim(),
    _priceUsdController.text.trim(),
    selectedSectionId,
    imagePaths,
  ].join('||');

  final now = DateTime.now();
  final canReuseKey =
      _lastSubmissionFingerprint == submissionFingerprint &&
      _lastIdempotencyKey != null &&
      _lastSubmissionAt != null &&
      now.difference(_lastSubmissionAt!) <= _idempotencyWindow;

  final idempotencyKey = canReuseKey ? _lastIdempotencyKey! : _uuid.v4();
  _lastSubmissionFingerprint = submissionFingerprint;
  _lastIdempotencyKey = idempotencyKey;
  _lastSubmissionAt = now;

  final productData = {
    "shopId": shopId,
    "productName": _nameController.text.trim(),
    "description": _descController.text.trim(),
    if (priceSyp != null) "price": priceSyp,
    if (priceUsd != null) "priceUSD": priceUsd,
    "sectionId": selectedSectionId,
    "image": compressedImage1,
    "image2": compressedImage2,
    "image3": compressedImage3,
  };

  try {
    final result = await ApiService.addProduct(
      productData,
      idempotencyKey: idempotencyKey,
    );

    if (result != null && result is Map && result['success'] == true) {
      final productId = result['productId'];

      if (!notify) {
        snackBar(context, "تمت إضافة المنتج بنجاح");
        
// 🔵 تحديث الواجهات الأخرى
//AppEvents().emit("refresh_home");
AppEvents().emit("refresh_sections");

setState(() {
  _nameController.clear();
  _descController.clear();
  _priceController.clear();
  _priceUsdController.clear();

  selectedSectionId = null;
  selectedSectionName = null;

  selectedImages = [null, null, null];
 isSaving = false;
});

// 🔵 لا نرجع للصفحة السابقة — نبقى هنا
return;

        //Navigator.pop(context);
        return;
      }

      final bodyData = {
        "contextType": "Product",
        "fromProductPage": true,
        "productName": _nameController.text.trim(),
        "senderId": shopId,
        "areaId": areaId,
        "relatedEntity": "Product",
        "relatedId": productId,
      };

      final notifyResult =
          await ApiService.sendAndDistribute(context, shopId, bodyData);

      String dialogMessage = "";

      if (notifyResult != null && notifyResult['success'] == true) {
        dialogMessage =
            "تمت إضافة منتجك بنجاح\nوإرسال الإشعار لجميع الزبائن";
      } else if (notifyResult != null && notifyResult['success'] == false) {
        dialogMessage =
            "لقد تجاوزت الحد المسموح به للإشعارات\nلن يتم إرسال إشعار جديد\n-------------------------\nتمت إضافة منتج جديد";
      } else {
        dialogMessage = "تمت إضافة المنتج بنجاح";
      }

      setState(() => isSaving = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          Future.delayed(const Duration(seconds: 3), () {
            Navigator.of(ctx).pop();
           // AppEvents().emit("refresh_home");
           AppEvents().emit("refresh_sections");
            Navigator.pop(context);
          });

          return WillPopScope(
            onWillPop: () async => false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                content: Text(
                  dialogMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: "Tajawal",
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      snackBar(context, "فشل في إضافة المنتج");
      setState(() => isSaving = false);
    }
  } catch (e) {
    snackBar(context, "حدث خطأ غير متوقع أثناء إضافة المنتج");
    setState(() => isSaving = false);
  }
}




  




   @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,

    // ✅ الأزرار مثبتة بالأسفل
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
                backgroundColor: notify ? const Color(0xFF5A9BD5) : Colors.white,
                side: const BorderSide(color: Color(0xFF5A9BD5), width: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                setState(() {
                  notify = !notify; // ✅ نفس عمل السويتش
                });
              },
              child: Text(
                "إرسال إشعار",
                style: TextStyle(
                  color: notify ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontFamily: "Tajawal",
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // زر إضافة
        SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    onPressed: isSaving ? null : _saveProduct,
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

    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ مسافة 2% من ارتفاع الشاشة
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // ✅ عنوان "إضافة منتج"
            Center(
  child: const Text(
    "إضافة منتج",
    style: TextStyle(
      fontSize: 22,
      fontFamily: "Tajawal",
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  ),
),
            const SizedBox(height: 20),

            // ✅ أزرار الصور
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: List.generate(3, (index) {
    final hasImage = selectedImages[index] != null;

    return Expanded(
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => _pickImage(index),

          // ⭐ ضغطة طويلة لحذف الصورة
          onLongPress: () {
            if (hasImage) {
              setState(() {
                selectedImages[index] = null;
              });
            }
          },

          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),

                  child: hasImage
                      ? ClipRRect(
                          key: ValueKey("img_$index"),
                          borderRadius: BorderRadius.circular(30),
                          child: Image.file(
                            selectedImages[index]!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Container(
                          key: ValueKey("empty_$index"),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: const Color(0xFF5A9BD5), width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              "صورة",
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // ⭐ النص تحت الصورة
              if (hasImage)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    "اضغط مطولاً للحذف",
                    style: TextStyle(
                      fontFamily: "Tajawal",
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }),
),
            const SizedBox(height: 20),

            // ✅ إدخال اسم المنتج
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "اسم المنتج"),
            ),
            const SizedBox(height: 16),

            // ✅ إدخال السعر
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: "السعر بالليرة السورية"),
            ),
            const SizedBox(height: 16),

            if (_isDollarEnabled) ...[
              TextField(
                controller: _priceUsdController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "السعر بالدولار (اختياري)",
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ✅ إدخال الوصف
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "الوصف"),
            ),
            const SizedBox(height: 20),

            // ✅ اختيار التصنيف كنص أزرق
            Center(
              child: GestureDetector(
                onTap: _showSectionDialog,
                child: Text(
                  selectedSectionName ?? "اختر التصنيف",
                  style: const TextStyle(
                    color: Color(0xFF5A9BD5),
                    fontSize: 28,
                    fontFamily: "Tajawal",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
}