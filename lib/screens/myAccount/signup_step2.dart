import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../providers/router_provider.dart';

class SignupStep2 extends StatefulWidget {
  const SignupStep2({super.key});

  @override
  State<SignupStep2> createState() => _SignupStep2State();
}

class _SignupStep2State extends State<SignupStep2> {
  final storeNameController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final List<TextEditingController> phoneControllers = [TextEditingController()];

  List<dynamic> categories = [];
  Map<String, dynamic>? selectedCategory;

  final storeFocus = FocusNode();
  final addressFocus = FocusNode();
  final descriptionFocus = FocusNode();

  double? selectedLat;
  double? selectedLng;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await ApiService.getCategories();
    if (result != null) {
      setState(() {
        categories = result;
      });
    }
  }

  Future<void> _saveShopData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('shopName', storeNameController.text.trim());
    await prefs.setString('address', addressController.text.trim());
    await prefs.setString('detailes', descriptionController.text.trim());
    await prefs.setInt('categoryId', selectedCategory?['categoryId'] ?? 0);

    if (selectedLat != null && selectedLng != null) {
      await prefs.setDouble('latitude', selectedLat!);
      await prefs.setDouble('longitude', selectedLng!);
    }

    final phones = phoneControllers.map((c) => c.text.trim()).where((p) => p.isNotEmpty).toList();
    await prefs.setStringList('shopPhones', phones);

    context.push(AppRoutes.signupStep3);
  }

  InputDecoration _inputDecoration(String label, IconData icon, FocusNode focusNode) {
    final isFocused = focusNode.hasFocus;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: isFocused ? Colors.blue : Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _showCategorySheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white, // 👈 ضع الخلفية هنا
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
    ),
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: categories.map((cat) {
              return ListTile(
                title: Text(cat['categoryName'], style: const TextStyle(fontFamily: 'Tajawal')),
                onTap: () {
                  setState(() {
                    selectedCategory = cat;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}

 final _formKey = GlobalKey<FormState>();

@override
Widget build(BuildContext context) {
  return WillPopScope(
    // عند الضغط على زر الرجوع يخرج من التطبيق
    onWillPop: () async {
      SystemNavigator.pop();
      return false;
    },
    child: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Form(
            key: _formKey, // ✅ ربط النموذج بالمفتاح
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // النصوص بالمنتصف
              children: [
                const Text(
                  "انضم لنا الآن",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 8),
                const Text(
                  "معلومات المحل",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: storeNameController,
                  focusNode: storeFocus,
                  decoration:
                      _inputDecoration("اسم المحل", Icons.store, storeFocus),
                  validator: (v) =>
                      v == null || v.isEmpty ? "مطلوب" : null,
                ),
                const SizedBox(height: 16),

                // زر يفتح البوتوم شيت لاختيار الفئة
                FormField<String>(
                  validator: (v) {
                    if (selectedCategory == null) {
                      return "مطلوب";
                    }
                    return null;
                  },
                  builder: (state) {
                    return InkWell(
                      onTap: _showCategorySheet,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "الفئة",
                          border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20)),
                          ),
                          errorText: state.errorText, // 👈 عرض رسالة الخطأ
                        ),
                        child: Text(
                          selectedCategory?['categoryName'] ?? "اختر الفئة",
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: addressController,
                  focusNode: addressFocus,
                  decoration: _inputDecoration(
                      "العنوان", Icons.location_on, addressFocus),
                  validator: (v) =>
                      v == null || v.isEmpty ? "مطلوب" : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  focusNode: descriptionFocus,
                  maxLines: 3,
                  decoration: _inputDecoration(
                      "الوصف", Icons.description, descriptionFocus),
                ),
                const SizedBox(height: 28),

                // ✅ حقول أرقام الهاتف مع زر إضافة
Column(
  children: [
    for (int i = 0; i < phoneControllers.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: phoneControllers[i],
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "رقم الهاتف ${i + 1}",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                validator: (v) {
                  if (i == 0 && (v == null || v.isEmpty)) {
                    return "مطلوب";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            // زر إضافة يظهر فقط إذا لم نصل للحد الأقصى
            if (i == phoneControllers.length - 1 && phoneControllers.length < 5)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    phoneControllers.add(TextEditingController());
                  });
                },
              ),
          ],
        ),
      ),
  ],
),
const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),

      // ✅ زر مثبت في الأسفل خارج السكرول
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // ✅ تحقق من النموذج قبل الحفظ
              if (_formKey.currentState!.validate()) {
                _saveShopData();
              }
            },
            child: const Text(
              "التالي",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
          ),
        ),
      ),
    ),
  );
}
}

/** اذا بدي زر مع تحميل
bool _isLoading = false;

@override
Widget build(BuildContext context) {
  return Scaffold(
    // باقي الكود كما هو ...
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);

                    await _saveShopData();

                    setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const CircularProgressIndicator(color: Color(0xFF5A9BD5))
              : const Text(
                  "التالي",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
        ),
      ),
    ),
  );
}
 */