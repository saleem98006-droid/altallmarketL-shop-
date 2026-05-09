import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../snackBar/snackbar.dart';
import '../../widgets/loading_dots_widget.dart';

class AddSectionPage extends StatefulWidget {
  const AddSectionPage({super.key});

  @override
  State<AddSectionPage> createState() => _AddSectionPageState();
}

class _AddSectionPageState extends State<AddSectionPage> {
  final TextEditingController _sectionController = TextEditingController();
  int? shopId;
  List<dynamic> sections = [];
  bool isSaving = false;


  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  Future<void> _loadShopId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      shopId = prefs.getInt("shopId");
    });
    if (shopId != null) {
      _fetchSections();
    }
  }

  Future<void> _fetchSections() async {
    if (shopId == null) return;
    final result = await ApiService.getSectionsByShop(shopId!);
    if (result != null && result["success"] == true) {
      setState(() {
        sections = result["sections"];
      });
    }
  }

  void _showCustomMessage(String message, Color bgColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addSection() async {
  if (shopId == null || _sectionController.text.isEmpty) {
    Navigator.pop(context);
    return;
  }

  setState(() => isSaving = true); // 🔥 بدء التحميل

  final result = await ApiService.addSection(
    shopId!,
    _sectionController.text,
    null,
  );

  if (result != null && result["success"] == true) {
    _sectionController.clear();
    await _fetchSections();

    snackBar(context, "تمت إضافة التصنيف بنجاح");

    setState(() => isSaving = false); // 🔥 إيقاف التحميل
    Navigator.pop(context);
  } else {
    snackBar(context, "فشل في اضافة التصنيف");
    setState(() => isSaving = false); // 🔥 إيقاف التحميل
  }
}

 Future<void> _addSection1() async {
    if (shopId == null || _sectionController.text.isEmpty) {
     snackBar(context, "الرجاء ادخال اسم التصنيف");
      return;
    }

    final result = await ApiService.addSection(shopId!, _sectionController.text, null);
    print("📌 Add section result: $result");

    if (result != null && result["success"] == true) {
      _sectionController.clear();
      _fetchSections();
      snackBar(context, "تمت إضافة التصنيف بنجاح");
    } else {
       snackBar(context, "فشل في اضافة التصنيف");
    }
  }
  Future<void> _deleteSection(int sectionId) async {
    final result = await ApiService.deleteSection(sectionId);
    if (result != null && result["success"] == true) {
      _fetchSections();
       snackBar(context,"تم حذف التصنيف");
    } else {
      snackBar(context,"فشل الحذف اعد المحاولة");
    }
  }
void _confirmDelete(int sectionId, bool hasProducts) {
  if (!hasProducts) {
    _deleteSection(sectionId);
  } else {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white, // الخلفية بيضاء
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // انحناء 40
            side: const BorderSide(
              color: Color(0xFF5A9BD5), // الإطار أزرق
              width: 0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "التصنيف يحتوي على منتجات\nلا يمكن الحذف\nعليك نقل المنتجات لقسم آخر",
                  style: TextStyle(
                    color: Colors.black, // الكتابة سوداء
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

          SizedBox(
  //width: MediaQuery.of(context).size.width * 0.6, // 60% من عرض الديالوغ
  width:100,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: Colors.red, // إطار أحمر
        width: 2,
      ),
      backgroundColor: Colors.white, // خلفية بيضاء
      foregroundColor: Colors.black, // كتابة سوداء
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ), 
    ),
    onPressed: () {
      Navigator.pop(context);
    },
    child: const Text(
      "موافق",
      style: TextStyle(fontSize: 16),
    ),
  ),
)



              ],
            ),
          ),
        );
      },
    );
  }
}

@override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    backgroundColor: Colors.white,

    // 🔥 زر تأكيد ثابت أسفل الشاشة ولا يتحرك مع الكيبورد
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    onPressed: isSaving ? null : _addSection,
    child: isSaving
        ? const LoadingDotsWidget()
        : const Text(
            "تأكيد",
            style: TextStyle(fontFamily: "Tajawal"),
          ),
  ),
),

    ),

    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: screenHeight * 0.07),

          TextField(
  controller: _sectionController,
  textAlign: TextAlign.right,
  decoration: InputDecoration(
    hintText: "اضف تصنيف",

    // 👈 تمت إضافة الأيقونة فقط بدون أي تعديل آخر
    prefixIcon: IconButton(
      icon: Image.asset("assets/images/Add1.png", height: 24, color: Color(0xFF5A9BD5)),
      onPressed: _addSection1,
    ),
  ),
),

          const SizedBox(height: 50),

          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: const Text(
              "التصنيفات",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // زر الحذف
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: GestureDetector(
                          onTap: () {
                            bool hasProducts = section["hasProducts"] ?? false;
                            _confirmDelete(section["sectionId"], hasProducts);
                          },
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF5A9BD5),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // اسم التصنيف
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            section["sectionName"],
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

}
