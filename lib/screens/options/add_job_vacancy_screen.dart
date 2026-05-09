import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../snackBar/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/loading_dots_widget.dart';

class AddJobVacancyScreen extends StatefulWidget {
  const AddJobVacancyScreen({super.key});

  @override
  State<AddJobVacancyScreen> createState() => _AddJobVacancyScreenState();
}

class _AddJobVacancyScreenState extends State<AddJobVacancyScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  final TextEditingController reqController = TextEditingController();
   int shopId = 0;

  bool loading = false;
  Future<void> loadShopId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      shopId = prefs.getInt("shopId") ?? 0;
    });
  }
 @override
  void initState() {
    super.initState();
    loadShopId();
  }

  Future<void> saveVacancy() async {
    if (titleController.text.isEmpty) {
        snackBar(context,"الرجاء إدخال عنوان الشاغر");
      return;
    }

    if (shopId == 0) {
      snackBar(context, "لم يتم تحميل بيانات المحل، أعد المحاولة");
      return;
    }

    setState(() => loading = true);

    try {
      final body = {
        "shopId": shopId,
        "jobTitle": titleController.text.trim(),
        "jobDescription": descController.text.trim(),
        "salary": salaryController.text.isEmpty
            ? null
            : int.tryParse(salaryController.text.trim()),
        "workHours": hoursController.text.trim(),
        "requirements": reqController.text.trim(),
        "isActive": true
      };

      final result = await ApiService.addJobVacancy(body);

      if (!mounted) return;
      setState(() => loading = false);

      if (result != null && result["success"] == true) {
        snackBar(context, "تمت الإضافة بنجاح");
        Navigator.pop(context, true);
      } else {
        final msg = result?["message"]?.toString();
        snackBar(context, msg ?? "حدث خطأ أثناء الإضافة");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      snackBar(context, "خطأ أثناء الاتصال بالسيرفر");
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: OutlinedButton(
              onPressed: loading ? null : saveVacancy,
              child: loading
                  ? const LoadingDotsWidget()
                  : const Text(
                      "حفظ",
                      style: TextStyle(
                        fontFamily: "Tajawal",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: height * 0.05),

              const Text(
                "إضافة شاغر عمل",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildLabel("العنوان"),
                      _buildField(titleController),

                      _buildLabel("الوصف"),
                      _buildField(descController, maxLines: 3),

                      _buildLabel("الراتب"),
                      _buildField(salaryController,
                          keyboard: TextInputType.number),

                      _buildLabel("ساعات العمل"),
                      _buildField(hoursController),

                      _buildLabel("الشروط"),
                      _buildField(reqController, maxLines: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: "Tajawal",
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}