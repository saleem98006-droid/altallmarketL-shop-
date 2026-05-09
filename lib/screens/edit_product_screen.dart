import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'snackBar/snackbar.dart';
import 'dart:typed_data';
import '../utils/image_compressor.dart';
import 'package:path_provider/path_provider.dart';
import '../core/app_events.dart';
import '../config/api_config.dart';
import '../widgets/loading_dots_widget.dart';





class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic>? offer;

  const EditProductScreen({super.key, required this.product, this.offer});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;

 File? image1File;
File? image2File;
File? image3File;

String? image1Url;
String? image2Url;
String? image3Url;

  bool isSaving = false;

  final ImagePicker _picker = ImagePicker();

  String? selectedSectionName;
  List<dynamic> sections = [];
  int? selectedSectionId;

  late Map<String, dynamic> oldProduct;
  Map<String, dynamic>? offer;
  late Map<String, dynamic> oldOffer;

  @override
  void initState() {
    super.initState();

    // 🟢 تحميل بيانات المنتج
    nameController = TextEditingController(text: widget.product['productName'] ?? '');
    priceController = TextEditingController(text: widget.product['price']?.toString() ?? '');
    descController = TextEditingController(text: widget.product['description'] ?? '');

  image1Url = widget.product['imageUrl1'];
image2Url = widget.product['imageUrl2'];
image3Url = widget.product['imageUrl3'];

    selectedSectionId = widget.product['sectionId'];

    // نسخة أصلية للمقارنة
 oldProduct = {
  "productName": widget.product['productName'] ?? '',
  "price": widget.product['price']?.toString() ?? '',
  "description": widget.product['description'] ?? '',
  "sectionId": widget.product['sectionId'],
  "imageUrl1": widget.product['imageUrl1'],
  "imageUrl2": widget.product['imageUrl2'],
  "imageUrl3": widget.product['imageUrl3'],
};

    // 🟢 تحميل العرض
    offer = widget.offer;
    if (offer != null) {
      oldOffer = {
        "offerType": offer?['offerType'],
        "discountValue": offer?['discountValue']?.toString(),
        "buyQuantity": offer?['buyQuantity']?.toString(),
        "getQuantity": offer?['getQuantity']?.toString(),
        "freeProductId": offer?['freeProductId']?.toString(),
        "startDate": offer?['startDate'],
        "endDate": offer?['endDate'],
        "isActive": offer?['isActive'],
      };
    }

    _loadSections();
  }

  // تحميل الأقسام
  Future<void> _loadSections() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;
    if (shopId == 0) return;

    final response = await ApiService.getSectionsByShop(shopId);

    if (response != null && response['sections'] != null) {
      setState(() {
        sections = response['sections'];

        selectedSectionName = sections.firstWhere(
          (s) => s['sectionId'] == selectedSectionId,
          orElse: () => null,
        )?['sectionName'];
      });
    }
  }

  // اختيار صورة
  Future<void> _pickImage(int index, {bool fromCamera = false}) async {
  final XFile? picked = await _picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
  );

  if (picked == null) return;

  final file = File(picked.path);

  setState(() {
    if (index == 1) {
      image1File = file;
      image1Url = null; // لأن الصورة الجديدة تستبدل القديمة
    } else if (index == 2) {
      image2File = file;
      image2Url = null;
    } else if (index == 3) {
      image3File = file;
      image3Url = null;
    }
  });
}

  // حذف صورة
  void _deleteImage(int index) {
  setState(() {
    if (index == 1) {
      image1File = null;
      image1Url = null;
    } else if (index == 2) {
      image2File = null;
      image2Url = null;
    } else if (index == 3) {
      image3File = null;
      image3Url = null;
    }
  });

  snackBar(context, "تم حذف الصورة");
}

  // صندوق الصورة
  Widget _buildImageBox(int index) {
  File? file;
  String? url;

  // اختيار الصورة حسب index
  if (index == 1) {
    file = image1File;
    url = image1Url;
  } else if (index == 2) {
    file = image2File;
    url = image2Url;
  } else if (index == 3) {
    file = image3File;
    url = image3Url;
  }

  return GestureDetector(
    onTap: () => _pickImage(index),
    onLongPress: () => _deleteImage(index),
    child: Container(
      width: MediaQuery.of(context).size.width * 0.25,
      height: 100,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF5A9BD5)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: _buildImageContent(file, url),
      ),
    ),
  );
}

Widget _buildImageContent(File? file, String? url) {
  if (file != null) {
    return Image.file(file, fit: BoxFit.cover);
  }

  if (url != null && url.isNotEmpty) {
    return Image.network(
      ApiConfig.baseUrl + url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _emptyImage(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  return _emptyImage();
}

Widget _emptyImage() {
  return const Center(
    child: Text(
      "صورة",
      style: TextStyle(
        fontFamily: "Tajawal",
        fontSize: 18,
        color: Color(0xFF5A9BD5),
      ),
    ),
  );
}

  // حفظ المنتج بدون كاش
 Future<bool> _saveProductChanges() async {
  final newData = {
    "productName": nameController.text.trim(),
    "price": double.tryParse(priceController.text.trim()) ?? 0,
    "description": descController.text.trim(),
    "sectionId": selectedSectionId,

    // الصور القديمة (روابط) إذا لم تتغير
    "imageUrl1": (image1Url == null || image1Url!.trim().isEmpty) ? null : image1Url,
"imageUrl2": (image2Url == null || image2Url!.trim().isEmpty) ? null : image2Url,
"imageUrl3": (image3Url == null || image3Url!.trim().isEmpty) ? null : image3Url,
  };

  bool productChanged = false;

  // مقارنة البيانات القديمة بالجديدة
  for (var key in oldProduct.keys) {
    if (oldProduct[key]?.toString() != newData[key]?.toString()) {
      productChanged = true;
      break;
    }
  }

  // إذا المستخدم اختار صورة جديدة → نعتبره تغيير
  if (image1File != null || image2File != null || image3File != null) {
    productChanged = true;
  }

  if (!productChanged) return true;

  final productId = widget.product['productId'];

  // 🔵 إرسال البيانات + الملفات إلى API
  final ok = await ApiService.updateProduct(
    productId,
    newData,
    image1File: image1File,
    image2File: image2File,
    image3File: image3File,
  );

  if (ok) {
    // تحديث المنتج مباشرة في الواجهة
    widget.product['productName'] = newData['productName'];
    widget.product['price'] = newData['price'];
    widget.product['description'] = newData['description'];
    widget.product['sectionId'] = newData['sectionId'];

    // تحديث الروابط الجديدة القادمة من السيرفر (لا نملكها لأن السيرفر لا يرجعها)
    // لذلك نتركها كما هي في newData
    widget.product['imageUrl1'] = newData['imageUrl1'];
    widget.product['imageUrl2'] = newData['imageUrl2'];
    widget.product['imageUrl3'] = newData['imageUrl3'];

    oldProduct = Map.from(newData);

    AppEvents().emit("refresh_sections");
    AppEvents().emit("refresh_product_detail");

    AppEvents().emit("refresh_section_products");

    return true;
  }

  snackBar(context, "فشل تعديل المنتج");
  return false;
}
  // حفظ العرض
  Future<bool> _saveOfferChanges() async {
    if (offer == null) return true;

    bool offerChanged = false;
    for (var key in oldOffer.keys) {
      if (oldOffer[key]?.toString() != offer![key]?.toString()) {
        offerChanged = true;
        break;
      }
    }

    if (!offerChanged) return true;

    final offerId = offer!['offerId'];
    final response = await ApiService.updateOffer(offerId, offer!);

    if (response != null && response['success'] == true) {
      
      AppEvents().emit("refresh_offers");
AppEvents().emit("refresh_product_detail");

             AppEvents().emit("refresh_section_products");
             return true;
    }

    snackBar(context, response?['message'] ?? "فشل تعديل العرض");
    return false;
  }

  // حفظ الكل
  Future<void> _saveAll() async {
    setState(() => isSaving = true);

    final bool productChanged = _hasProductChanges();
    final bool offerChanged = _hasOfferChanges();

    if (!productChanged && !offerChanged) {
      setState(() => isSaving = false);
      snackBar(context, "لا يوجد تعديل");
      Navigator.pop(context, false);
      return;
    }

    final okProduct = productChanged ? await _saveProductChanges() : true;
    final okOffer = offerChanged ? await _saveOfferChanges() : true;

    if (okProduct && okOffer) {
      snackBar(context, "تم الحفظ بنجاح");
      AppEvents().emit("refresh_offers");
AppEvents().emit("refresh_sections");
             AppEvents().emit("refresh_section_products");
      Navigator.pop(context, true);
    } else {
      snackBar(context, "فشل الحفظ");
    }

    setState(() => isSaving = false);
  }

  bool _hasProductChanges() {
  // تغييرات النصوص
  bool changed = 
      nameController.text != oldProduct['productName'] ||
      priceController.text != oldProduct['price'] ||
      descController.text != oldProduct['description'] ||
      selectedSectionId != oldProduct['sectionId'];

  // تغييرات الصور
  if (image1File != null || image2File != null || image3File != null) {
    changed = true;
  }

  // حذف صورة قديمة
  if (image1Url == null && oldProduct['imageUrl1'] != null) changed = true;
  if (image2Url == null && oldProduct['imageUrl2'] != null) changed = true;
  if (image3Url == null && oldProduct['imageUrl3'] != null) changed = true;

  return changed;
}

 
  bool _hasOfferChanges() {
    if (offer == null) return false;

    return offer!['offerType']?.toString() != oldOffer['offerType']?.toString() ||
        offer!['discountValue']?.toString() != oldOffer['discountValue']?.toString() ||
        offer!['buyQuantity']?.toString() != oldOffer['buyQuantity']?.toString() ||
        offer!['getQuantity']?.toString() != oldOffer['getQuantity']?.toString() ||
        offer!['freeProductId']?.toString() != oldOffer['freeProductId']?.toString() ||
        offer!['startDate']?.toString() != oldOffer['startDate']?.toString() ||
        offer!['endDate']?.toString() != oldOffer['endDate']?.toString() ||
        offer!['isActive']?.toString() != oldOffer['isActive']?.toString();
  }


 

 
@override
Widget build(BuildContext context) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(

     

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

Center(
  child: const Text(
    "تعديل المنتج",
    style: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: "Tajawal",
    ),
  ),
),
            const SizedBox(height: 16),

            // ✔ الصور
            Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
   _buildImageBox(1),
_buildImageBox(2),
_buildImageBox(3),
  ],
),
            const SizedBox(height: 5),

            Center(
              child: const Text(
                "اضغط للتغيير\n(ضغطة طويلة لللحذف)",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ),

            const SizedBox(height: 16),

            // ✔ اسم المنتج
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "اسم المنتج"),
            ),
            const SizedBox(height: 12),

            // ✔ السعر
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "السعر"),
            ),
            const SizedBox(height: 12),

            // ✔ الوصف
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "الوصف"),
            ),
            const SizedBox(height: 12),

            // ⭐⭐ التصنيف — BottomSheet بدل Dropdown ⭐⭐
          GestureDetector(
  onTap: () => _openSectionSheet(context),
  child: AbsorbPointer(
    child: TextField(
      style: const TextStyle(
        color: Colors.black,        // ← لون النص الحقيقي لو كان هناك قيمة
        fontFamily: "Tajawal",
      ),
      decoration: InputDecoration(
        labelText: "التصنيف",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: selectedSectionName ?? "اختر التصنيف",
        hintStyle: const TextStyle(
          color: Colors.black,      // ← هذا هو المهم
          fontFamily: "Tajawal",
        ),
        suffixIcon: const Icon(Icons.keyboard_arrow_down),
      ),
    ),
  ),
),

            const SizedBox(height: 16),

            // 🟢 قسم العرض (كما هو)
            if (offer != null)
              OfferEditor(
                offer: offer!,
                onChanged: (updatedOffer) {
                  setState(() {
                    offer = updatedOffer;
                  });
                },
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // ✔ زر الحفظ كما هو
      bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(16.0),
  child: SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: isSaving ? null : _saveAll,
      child: isSaving
          ? const LoadingDotsWidget()
          : const Text(
              "حفظ",
              style: TextStyle(
                fontFamily: "Tajawal",
                fontSize: 18,
              ),
            ),
    ),
  ),
),
    ),
  );
}
void _openSectionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
            ),
            child: ListView.builder(
              controller: scrollController,
              itemCount: sections.length,
              itemBuilder: (_, index) {
                final section = sections[index];
                return ListTile(
                  title: Text(
                    section['sectionName'],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: "Tajawal",
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      selectedSectionId = section['sectionId'];
                      selectedSectionName = section['sectionName'];
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          );
        },
      );
    },
  );
}


}

// ----------------------
// ويدجت مستقلة لتعديل العرض
// ----------------------
class OfferEditor extends StatefulWidget {
  final Map<String, dynamic> offer;
  final void Function(Map<String, dynamic>) onChanged;

  const OfferEditor({
    super.key,
    required this.offer,
    required this.onChanged,
  });

  @override
  State<OfferEditor> createState() => _OfferEditorState();
}

class _OfferEditorState extends State<OfferEditor> {
  late String? offerType;
  late TextEditingController discountController;
  late TextEditingController buyQtyController;
  late TextEditingController getQtyController;
  late TextEditingController freeProductController;
  late TextEditingController freeProductNameController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  DateTime? startDate;
  DateTime? endDate;
  bool isActive = true;

  List<dynamic> products = [];
  int? shopId;

  @override
  void initState() {
    super.initState();

    offerType = widget.offer['offerType'];

    discountController = TextEditingController(text: widget.offer['discountValue']?.toString() ?? '');
    buyQtyController = TextEditingController(text: widget.offer['buyQuantity']?.toString() ?? '');
    getQtyController = TextEditingController(text: widget.offer['getQuantity']?.toString() ?? '');

    freeProductController = TextEditingController(text: widget.offer['freeProductId']?.toString() ?? '');
    freeProductNameController = TextEditingController(
      text: widget.offer['freeProductName']?.toString() ?? '',
    );

    isActive = widget.offer['isActive'] == true;

    startDate = widget.offer['startDate'] != null
        ? DateTime.tryParse(widget.offer['startDate'].toString())
        : null;

    endDate = widget.offer['endDate'] != null
        ? DateTime.tryParse(widget.offer['endDate'].toString())
        : null;

    _startDateController = TextEditingController(
      text: startDate != null ? _formatDateTime(startDate) : "",
    );

    _endDateController = TextEditingController(
      text: endDate != null ? _formatDateTime(endDate) : "",
    );

    _initShopAndProducts(); // ⬅️ تحميل المنتجات هنا
  }

  // تحميل المنتجات من قاعدة البيانات
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

  void _notifyChange() {
    widget.onChanged({
      "offerId": widget.offer['offerId'],
      "offerType": offerType,
      "discountValue": double.tryParse(discountController.text),
      "buyQuantity": int.tryParse(buyQtyController.text),
      "getQuantity": int.tryParse(getQtyController.text),
      "freeProductId": int.tryParse(freeProductController.text),
      "freeProductName": freeProductNameController.text,
      "startDate": startDate?.toIso8601String(),
      "endDate": endDate?.toIso8601String(),
      "isActive": isActive,
    });
  }

  // فتح قائمة اختيار المنتجات
 void _openProductSelector() async {
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
                // حفظ الاسم
                freeProductNameController.text = p['productName'];

                // حفظ الرقم (مخفي عن المستخدم)
                freeProductController.text = p['productId'].toString();

                Navigator.pop(context);
                _notifyChange();
              },
            );
          }).toList(),
        ),
      );
    },
  );
}

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? (startDate ?? now) : (endDate ?? now);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;

    final fullDateTime = DateTime(
      pickedDate.year, pickedDate.month, pickedDate.day,
      pickedTime.hour, pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        startDate = fullDateTime;
        _startDateController.text = _formatDateTime(fullDateTime);
      } else {
        endDate = fullDateTime;
        _endDateController.text = _formatDateTime(fullDateTime);
      }
    });

    _notifyChange();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "لم يتم التحديد";
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
           "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _getOfferTypeName(String? type) {
    switch (type) {
      case "DirectDiscount":
        return "خصم مباشر";
      case "BuyXGetY":
        return "اشترِ X واحصل Y";
      case "FreeItem":
        return "هدية مجانية";
      default:
        return "غير معروف";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),

        Center(
          child: const Text(
            "تعديل العرض",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: "Tajawal",
            ),
          ),
        ),

        const SizedBox(height: 25),

        TextFormField(
          initialValue: _getOfferTypeName(offerType),
          readOnly: true,
          decoration: const InputDecoration(
            labelText: "نوع العرض",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        if (offerType == "DirectDiscount") ...[
          TextField(
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "قيمة الخصم",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _notifyChange(),
          ),
        ] else if (offerType == "BuyXGetY") ...[
          TextField(
            controller: buyQtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "الكمية المطلوبة (X)",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: getQtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "كمية الهدية (Y)",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _notifyChange(),
          ),
        ] else if (offerType == "FreeItem") ...[
          TextField(
            controller: freeProductNameController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: "اسم المنتج المجاني",
              border: OutlineInputBorder(),
            ),
            onTap: _openProductSelector,
          ),
          const SizedBox(height: 8),
          const Text(
            "اضغط لاختيار المنتج من القائمة",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],

        const SizedBox(height: 20),

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
            onTap: () => _pickDateTime(isStart: true),
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
            onTap: () => _pickDateTime(isStart: false),
          ),
        ),
      ],
    );
  }
}

