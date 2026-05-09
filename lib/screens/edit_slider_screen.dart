import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import '../services/api_service.dart';
import 'snackBar/snackbar.dart';
import '../config/api_config.dart';
import '../utils/image_compressor.dart';
import '../core/app_events.dart';
import '../widgets/loading_dots_widget.dart';

class EditSliderScreen extends StatefulWidget {
  final Map<String, dynamic> slider;

  const EditSliderScreen({super.key, required this.slider});

  @override
  State<EditSliderScreen> createState() => _EditSliderScreenState();
}

class _EditSliderScreenState extends State<EditSliderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  late String targetType;
  late int? targetId;
  late bool isGlobal;

  DateTime? startDate;
  DateTime? endDate;
String? imageUrl;        // رابط الصورة القادمة من السيرفر
File? imageFile;         // الصورة الجديدة المختارة
bool newImageSelected = false; 
 

  List<Map<String, dynamic>> dropdownItems = [];
  bool _isLoading = false;
  bool _isSaving = false;
 

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.slider['title'] ?? "");
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();

    targetType = widget.slider['targetType']?.toString() ?? "";
    targetId = widget.slider['targetId'];
   
dynamic g = widget.slider['isGlobal'];

if (g is bool) {
  isGlobal = g;
} else if (g is int) {
  isGlobal = g == 1;
} else if (g is String) {
  isGlobal = g == "1" || g.toLowerCase() == "true";
} else {
  isGlobal = false;
}
    startDate = DateTime.tryParse(widget.slider['startDate'] ?? "");
    endDate = DateTime.tryParse(widget.slider['endDate'] ?? "");

   if (startDate != null) {
  final d = startDate!;
  int hour = d.hour % 12;
  if (hour == 0) hour = 12;
  String period = d.hour >= 12 ? "PM" : "AM";

  _startDateController.text =
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
      "${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $period";
}

if (endDate != null) {
  final d = endDate!;
  int hour = d.hour % 12;
  if (hour == 0) hour = 12;
  String period = d.hour >= 12 ? "PM" : "AM";

  _endDateController.text =
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
      "${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $period";
}

   imageUrl = widget.slider['imageUrl']; 

    _loadDropdownItems();
  }

  Future<void> _loadDropdownItems() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt("shopId") ?? 5;

      final products = await ApiService.getProductsByShop(shopId);
      final offers = await ApiService.getActiveOffersByShop(shopId);
      final discounts = await ApiService.getActiveDiscountsByShop(shopId);

      final List<Map<String, dynamic>> p = products ?? [];
      final List<Map<String, dynamic>> o = offers ?? [];
      final List<Map<String, dynamic>> d = discounts ?? [];

      final List<Map<String, dynamic>> items = [];

      for (final product in p) {
        final productId = product["ProductID"] ?? product["productId"];
        String label = (product["ProductName"] ?? product["productName"] ?? "منتج").toString();

        final offer = o.firstWhereOrNull((m) => m["ProductID"] == productId);
        final discount = d.firstWhereOrNull((m) => m["ProductID"] == productId);

        if (offer != null) {
          label += " (عرض)";
          items.add({"label": label, "type": "Offer", "id": offer["OfferID"]});
        } else if (discount != null) {
          label += " (خصم)";
          items.add({"label": label, "type": "Discount", "id": discount["OfferID"]});
        } else {
          items.add({"label": label, "type": "Product", "id": productId});
        }
      }

      setState(() {
        dropdownItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

 Future<void> _pickImage() async {
  final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  setState(() {
    imageFile = File(picked.path);
    newImageSelected = true;
  });
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
      return Padding(
        padding: const EdgeInsets.only(right: 16, left: 16, top: 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              if (_isLoading) const LinearProgressIndicator(),

              Expanded(
                child: ListView.builder(
                  itemCount: dropdownItems.length,
                  itemBuilder: (context, index) {
                    final item = dropdownItems[index];
                    final bool isPlaceholder = item["type"] == "Placeholder";

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        enabled: !isPlaceholder,
                        title: Text(
                          item["label"],
                          textAlign: TextAlign.right,        // 🔥 النص من اليمين
                          textDirection: TextDirection.rtl,  // 🔥 اتجاه الكتابة يمين
                          style: const TextStyle(
                            fontSize: 18,
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
      );
    },
  );

  if (result != null && result["type"] != "Placeholder") {
    setState(() {
      targetType = result["type"];
      targetId = result["id"];
    });
  }
}


  Future<void> _saveChanges() async {
    if (startDate == null || endDate == null) {
      snackBar(context,"يرجى اختيار تاريخ البداية والنهاية للسلايدر الداخلي");
      return;
    }

    final newData = {
      "title": targetType == "Image" ? _titleController.text.trim() : "",
      "targetType": targetType,
      "targetId": targetType != "Image" ? targetId : null,
      
      "startDate": startDate?.toIso8601String(),
      "endDate": endDate?.toIso8601String(),
    };

    final oldData = {
      "title": widget.slider['title'] ?? "",
      "targetType": widget.slider['targetType'] ?? "",
      "targetId": widget.slider['targetId'],
     
      "startDate": widget.slider['startDate'],
      "endDate": widget.slider['endDate'],
    };

    bool noChanges = const MapEquality().equals(newData, oldData);

// إذا الصورة تغيّرت → اعتبر أن هناك تعديل
if (imageFile != null) {
  noChanges = false;
}

if (noChanges) {
  snackBar(context,"لا يوجد تعديل على البيانات");
  return;
}

    setState(() => _isSaving = true);

    final success = await ApiService.updateSlider(
  widget.slider['sliderId'],
  newData,
  imageFile: imageFile,   // ← مهم جدًا
);
 
    setState(() => _isSaving = false);

    if (success) {
        snackBar(context,"تم تعديل السلايدر بنجاح");
        AppEvents().emit("refresh_sliders");

    //AppEvents().emit("refresh_section_products");
      Navigator.pop(context, true);
    } else {      
      snackBar(context,"فشل في تعديل السلايدر");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                const Text(
                  "تعديل السلايدر",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Tajawal",
                  ),
                ),

                const SizedBox(height: 20),

                if (targetType != "Image") ...[
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "اختيار منتج / عرض / خصم",
                        border: OutlineInputBorder(),
                      ),
                      onTap: _openTargetBottomSheet,
                      controller: TextEditingController(
                        text: dropdownItems.firstWhereOrNull(
                              (e) => e["id"] == targetId && e["type"] == targetType,
                            )?["label"] ??
                            "",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (targetType == "Image") ...[
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "عنوان السلايدر",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                 SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      backgroundColor:
          newImageSelected ? const Color(0xFF5A9BD5) : Colors.white,
      side: const BorderSide(color: Color(0xFF5A9BD5), width: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    onPressed: () async {
      await _pickImage(); // ← دالتك الحالية

      setState(() {
        newImageSelected = true; // ← يتغير فقط عند اختيار صورة جديدة
      });
    },
    child: Text(
      newImageSelected ? "تم الاختيار" : "اختيار صورة",
      style: TextStyle(
        color: newImageSelected ? Colors.white : Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Tajawal',
      ),
    ),
  ),
),

                  const SizedBox(height: 10),

                 if (imageFile != null)
  ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.file(
      imageFile!,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  )
else if (imageUrl != null && imageUrl!.isNotEmpty)
  ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.network(
      ApiConfig.baseUrl + imageUrl! + "?v=${DateTime.now().millisecondsSinceEpoch}",
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),

                  const SizedBox(height: 20),
                ],

               Directionality(
  textDirection: TextDirection.rtl,
  child: TextField(
    controller: _startDateController,
    readOnly: true,
    enabled: !isGlobal, // ← يمنع التعديل ويجعل الحقل رمادي

    decoration: InputDecoration(
      labelText: "تاريخ البداية",

      // 🔥 إذا كان خارجي → بدون إطار
      border: isGlobal
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            )
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),

      // 🔥 لون النص
      labelStyle: TextStyle(
        color: isGlobal ? Colors.grey : Colors.black,
      ),

      // 🔥 خلفية رمادية عند كونه خارجي
      filled: isGlobal,
      fillColor: isGlobal ? Colors.grey.shade200 : Colors.white,
    ),

    // 🔥 منع الضغط عند كونه خارجي
    onTap: isGlobal ? null : () => _selectDateTime(context, _startDateController, true),
  ),
),

                const SizedBox(height: 16),

               Directionality(
  textDirection: TextDirection.rtl,
  child: TextField(
    controller: _endDateController,
    readOnly: true,
    enabled: !isGlobal, // ← يمنع التعديل ويجعل الحقل رمادي
    decoration: InputDecoration(
      labelText: "تاريخ النهاية",

      // 🔥 إذا كان خارجي → بدون إطار
      border: isGlobal
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            )
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),

      // 🔥 لون النص
      labelStyle: TextStyle(
        color: isGlobal ? Colors.grey : Colors.black,
      ),

      // 🔥 خلفية رمادية عند كونه خارجي
      filled: isGlobal,
      fillColor: isGlobal ? Colors.grey.shade200 : Colors.white,
    ),

    // 🔥 منع الضغط عند كونه خارجي
    onTap: isGlobal ? null : () => _selectDateTime(context, _endDateController, false),
  ),
),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const LoadingDotsWidget()
                : const Text(
                    "تأكيد",
                    style: TextStyle(fontFamily: "Tajawal"),
                  ),
          ),
        ),
      ),
    );
  }
}