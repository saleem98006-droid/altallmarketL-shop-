import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';
import '../../services/api_service.dart';
import 'package:collection/collection.dart';
import '../snackBar/snackbar.dart';
import '../../core/app_events.dart';
import '../../utils/image_compressor.dart';
import '../../widgets/loading_dots_widget.dart';

class AddSliderScreen extends StatefulWidget {
  const AddSliderScreen({super.key});

  @override
  State<AddSliderScreen> createState() => _AddSliderScreenState();
}

class _AddSliderScreenState extends State<AddSliderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String title = "";
  String? selectedTargetType; // Product / Offer / Discount
  int? targetId;

  String sliderType = "داخلي";
  DateTime? startDate;
  DateTime? endDate;

 List<File?> selectedImages = [null];
  String? imageBase64;

  int? shopId;
  List<Map<String, dynamic>> dropdownItems = [];
  String sliderMode = "product"; // "product" أو "image"
  bool _isLoading = false;
  String? _loadError;

  // Controllers للتواريخ
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Controllers لحقل نوع السلايدر وحقل المنتج/العرض/الخصم
  final TextEditingController _sliderModeController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  bool _isSaving = false;
  bool imageSelected = false;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    _sliderModeController.text = "منتج";
    _loadShopIdAndData();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _sliderModeController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadShopIdAndData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      dropdownItems = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      shopId = prefs.getInt("shopId") ?? 5;

      final products = await ApiService.getProductsByShop(shopId!);
      final offers = await ApiService.getActiveOffersByShop(shopId!);
      final discounts = await ApiService.getActiveDiscountsByShop(shopId!);

      final List<Map<String, dynamic>> p = products ?? [];
      final List<Map<String, dynamic>> o = offers ?? [];
      final List<Map<String, dynamic>> d = discounts ?? [];

      final List<Map<String, dynamic>> items = [];

      for (final product in p) {
        final productId = product["ProductID"] ?? product["productId"];
        String label =
            (product["ProductName"] ?? product["productName"] ?? "منتج")
                .toString();

        final offer = o.firstWhereOrNull(
          (m) => m["ProductID"] == productId || m["productId"] == productId,
        );

        final discount = d.firstWhereOrNull(
          (m) => m["ProductID"] == productId || m["productId"] == productId,
        );

        if (offer != null) {
          label += " (عرض)";
          items.add({
            "label": label,
            "type": "Offer",
            "id": offer["OfferID"] ?? offer["offerId"],
          });
        } else if (discount != null) {
          label += " (خصم)";
          items.add({
            "label": label,
            "type": "Discount",
            "id": discount["OfferID"] ?? discount["discountId"],
          });
        } else {
          items.add({
            "label": label,
            "type": "Product",
            "id": productId,
          });
        }
      }

      if (items.isEmpty) {
        items.add({
          "label": "لا توجد بيانات متاحة",
          "type": "Placeholder",
          "id": -1,
        });
      }

      setState(() {
        dropdownItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "خطأ أثناء تحميل البيانات: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(int index) async {
  final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

  if (picked != null) {
    setState(() {
      selectedImages[index] = File(picked.path);
    });
  }
}

  Future<void> _selectDateTime(
  BuildContext context,
  TextEditingController controller,
  bool isStart,
) async {
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

        if (isStart) {
          startDate = fullDateTime;
        } else {
          endDate = fullDateTime;
        }
      });
    }
  }
}

 Future<void> _openSliderModeBottomSheet() async {
  final String? result = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white, // الخلفية بيضاء
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(50)), // انحناء 40
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.only(right: 16), // ← مسافة بادئة من اليمين
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                      title: const Text(
                        "منتج",
                        style: TextStyle(fontSize: 18), // 👈 هنا تغيّرين الحجم
                      ),
                      onTap: () => Navigator.pop(ctx, "product"),
                    ),

                    ListTile(
                        title: const Text(
                          "صورة",
                          style: TextStyle(fontSize: 18),
                        ),
                        onTap: () => Navigator.pop(ctx, "image"),
                      ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );

  if (result != null) {
    setState(() {
      sliderMode = result;
      _sliderModeController.text = result == "product" ? "منتج" : "صورة";
      title = "";
      selectedImages[0] = null;
      selectedTargetType = null;
      targetId = null;
      _targetController.clear();
    });
  }
}

  Future<void> _openTargetBottomSheet() async {
  if (dropdownItems.isEmpty) return;

  final Map<String, dynamic>? result =
      await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: Colors.white, 
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 16, top: 16),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                if (_isLoading) const LinearProgressIndicator(),

                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _loadError!,
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  ),

                Expanded(
                  child: ListView.builder(
                    itemCount: dropdownItems.length,
                    itemBuilder: (context, index) {
                      final item = dropdownItems[index];
                      final bool isPlaceholder = item["type"] == "Placeholder";

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4), // ← مسافة أقل
                        child: ListTile(
                          enabled: !isPlaceholder,
                          title: Text(
                            item["label"],
                            style: const TextStyle(
                              fontSize: 18, // ← خط أكبر
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: isPlaceholder
                              ? null
                              : () => Navigator.pop<Map<String, dynamic>>(ctx, item),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (result != null && result["type"] != "Placeholder") {
    setState(() {
      selectedTargetType = result["type"];
      targetId = result["id"];
      _targetController.text = result["label"];
    });
  }
}

  Future<void> _saveSlider() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

     if (sliderMode == "image" && selectedImages[0] != null) {
  imageBase64 = await ImageCompressor.compressFile(selectedImages[0]);
}

      if (sliderMode == "product") {
        if (selectedTargetType == null || targetId == null) {
          
          snackBar(context, "يرجى اختيار منتج أو عرض أو خصم صالح");
          return;
        }
      }

      if (sliderMode == "image") {
        if (imageBase64 == null) {
          
           snackBar(context, " يرجى اختيار صورة");
          return;
        }
        if (title.trim().isEmpty) {
         
          snackBar(context,"يرجى إدخال عنوان السلايدر");
          return;
        }
      }

      if (sliderType == "داخلي") {
        if (startDate == null || endDate == null) {
          
          snackBar(context,"يرجى اختيار تاريخ البداية والنهاية للسلايدر الداخلي");
          return;
        }
        if (endDate!.isBefore(startDate!)) {
          
          snackBar(context,"تاريخ النهاية يجب أن يكون بعد البداية");
          return;
        }
      } else if (sliderType == "خارجي") {
        startDate = DateTime.now();
        endDate = DateTime.now().add(const Duration(hours: 24));
      }

     final sliderData = {
  "title": title,
  "image": imageBase64,
  "targetType": sliderMode == "product" ? selectedTargetType : "Image",
  "targetId": sliderMode == "product" ? targetId : 0,
  "isGlobal": sliderType == "داخلي" ? 0 : 1,
  "shopId": shopId,
  "startDate": startDate?.toIso8601String(),
  "endDate": endDate?.toIso8601String(),
  "isActive": true,
};



      try {
        setState(() {
          _isSaving = true;
        });

        final result = await ApiService.addSlider(sliderData);

        if (result["success"] == true) {
         // AppEvents().emit("refresh_home");
          AppEvents().emit("refresh_sliders");
          snackBar(context,result["message"] ?? "تم حفظ السلايدر بنجاح");
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(result["message"] ?? "❌ فشل في حفظ السلايدر")),
          );
        }
      } catch (e) {
        
         snackBar(context,"خطأ أثناء الحفظ: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Center(
                  child: const Text(
                    "إضافة سلايدر",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Tajawal",
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // نوع السلايدر (BottomSheet)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextFormField(
                    controller: _sliderModeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "نوع السلايدر",
                      border: OutlineInputBorder(),
                    ),
                    onTap: _openSliderModeBottomSheet,
                  ),
                ),
                const SizedBox(height: 20),

                if (sliderMode == "product") ...[
                  if (_isLoading) const LinearProgressIndicator(),
                  if (_loadError != null)
                    Text(
                      _loadError!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  // اختيار منتج / عرض / خصم (BottomSheet)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: TextFormField(
                      controller: _targetController,
                      readOnly: true,
                      decoration:  InputDecoration(
  labelText: "اختيار منتج / عرض / خصم",
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: Colors.red, width: 2),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: Colors.red, width: 2),
  ),
),
                      onTap: _openTargetBottomSheet,
                      validator: (val) {
                        if (sliderMode == "product") {
                          if (selectedTargetType == null || targetId == null) {
                            return "يرجى اختيار عنصر صالح";
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (sliderMode == "image") ...[
                 Directionality(
  textDirection: TextDirection.rtl,
  child: TextFormField(
    decoration:  InputDecoration(
  labelText: "عنوان السلايدر",
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: Colors.red, width: 2),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: Colors.red, width: 2),
  ),
),
    validator: (val) =>
        val == null || val.isEmpty ? "العنوان مطلوب" : null,
    onSaved: (val) => title = val ?? "",
  ),
),
                  const SizedBox(height: 20),

                 SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      backgroundColor:
          imageSelected ? const Color(0xFF5A9BD5) : Colors.white,
      side: const BorderSide(color: Color(0xFF5A9BD5), width: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    onPressed: () async {
  await _pickImage(0);

  if (selectedImages[0] != null) {
    final bytes = await selectedImages[0]!.readAsBytes();

    setState(() {
      imageSelected = true;
      imageBytes = bytes; // ← الآن الصورة تُعرض بشكل صحيح
    });
  }
},
    child: Text(
      imageSelected ? "تم الاختيار" : "اختيار صورة", // 🔥 النص يتغير هنا
      style: TextStyle(
        color: imageSelected ? Colors.white : Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Tajawal',
      ),
    ),
  ),
),
                  const SizedBox(height: 10),

                  if (imageBytes != null)
  Center(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20), // 🔥 حواف منحنية
      child: Image.memory(
        imageBytes!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    ),
  ),
                  const SizedBox(height: 20),
                ],

          Center(
  child: Container(
    width: MediaQuery.of(context).size.width * 0.92, // 90%
    child: SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: "داخلي",
          label: Text(
            "داخلي",
            style: TextStyle(fontFamily: "Tajawal", fontSize: 18),
          ),
        ),
        ButtonSegment<String>(
          value: "خارجي",
          label: Text(
            "خارجي",
            style: TextStyle(fontFamily: "Tajawal", fontSize: 18),
          ),
        ),
      ],
      selected: {sliderType},
      onSelectionChanged: (newValue) {
        setState(() {
          sliderType = newValue.first;

          if (sliderType == "خارجي") {
            startDate = DateTime.now();
            endDate = DateTime.now().add(const Duration(hours: 24));
            _startDateController.clear();
            _endDateController.clear();
          }
        });
      },

      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(
          const Size(double.infinity, 50), // 🔥 الارتفاع الحقيقي
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 13), // 🔥 يرفع المحتوى
        ),
        visualDensity: const VisualDensity(
          vertical: 0.5, // 🔥 يوسع الارتفاع أكثر
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,

        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        side: MaterialStateProperty.all(
          const BorderSide(color: Color(0xFF5A9BD5)),
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return Color(0xFF5A9BD5);
            }
            return Colors.white;
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.grey;
          },
        ),
      ),
    ),
  ),
),
                const SizedBox(height: 20),

                if (sliderType == "داخلي") ...[
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
                      onTap: () => _selectDateTime(context, _startDateController, true),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      onTap: () => _selectDateTime(context, _endDateController, false),
                    ),
                  ),
                ],

                if (sliderType == "خارجي")
                 Container(
  padding: const EdgeInsets.all(12),
  alignment: Alignment.center, // 🔥 يجعل النص بالمنتصف
  child: const Text(
    "هذا السلايدر صالح لمدة 24 ساعة فقط",
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),

      // زر الحفظ مثبت بالأسفل بنفس تصميم OutlinedButton
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSaving ? null : _saveSlider,
            child: _isSaving
                ? const LoadingDotsWidget()
                : const Text(
                    "حفظ",
                    style: TextStyle(fontFamily: "Tajawal"),
                  ),
          ),
        ),
      ),
    );
  }
}