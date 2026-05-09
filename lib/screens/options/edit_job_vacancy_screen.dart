import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../snackBar/snackbar.dart';
import '../../widgets/loading_dots_widget.dart';

class EditJobVacancyScreen extends StatefulWidget {
  final Map<String, dynamic>? vacancy;

  const EditJobVacancyScreen({super.key, this.vacancy});

  @override
  State<EditJobVacancyScreen> createState() => _EditJobVacancyScreenState();
}

class _EditJobVacancyScreenState extends State<EditJobVacancyScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  final TextEditingController reqController = TextEditingController();

  bool loading = false;
  late int vacancyId;

  // البيانات الأصلية
  late Map<String, dynamic> originalData;

  @override
  void initState() {
    super.initState();

    // تحميل البيانات بعد بناء الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      final fallbackArgs = (routeArgs is Map)
          ? Map<String, dynamic>.from(routeArgs)
          : <String, dynamic>{};
      final data = widget.vacancy ?? fallbackArgs;

      if (data.isEmpty) {
        if (mounted) {
          snackBar(context, "تعذر تحميل بيانات الشاغر");
          Navigator.pop(context, false);
        }
        return;
      }

      originalData = Map<String, dynamic>.from(data);
      vacancyId = data["VacancyID"];

      titleController.text = data["JobTitle"] ?? "";
      descController.text = data["JobDescription"] ?? "";
      salaryController.text = data["Salary"]?.toString() ?? "";
      hoursController.text = data["WorkHours"] ?? "";
      reqController.text = data["Requirements"] ?? "";

      setState(() {});
    });
  }

  Future<void> updateVacancy() async {
    if (titleController.text.isEmpty) {
      snackBar(context, "الرجاء إدخال عنوان الشاغر");
      return;
    }

    // البيانات القديمة
    final oldTitle = originalData["JobTitle"] ?? "";
    final oldDesc = originalData["JobDescription"] ?? "";
    final oldSalary = originalData["Salary"]?.toString() ?? "";
    final oldHours = originalData["WorkHours"] ?? "";
    final oldReq = originalData["Requirements"] ?? "";

    // البيانات الجديدة
    final newTitle = titleController.text;
    final newDesc = descController.text;
    final newSalary = salaryController.text;
    final newHours = hoursController.text;
    final newReq = reqController.text;

    // مقارنة القيم
    final noChanges =
        oldTitle == newTitle &&
        oldDesc == newDesc &&
        oldSalary == newSalary &&
        oldHours == newHours &&
        oldReq == newReq;

    if (noChanges) {
      snackBar(context, "لم يتم تعديل أي بيانات");
      Navigator.pop(context, false);
      return;
    }

    setState(() => loading = true);

    final body = {
      "vacancyId": vacancyId,
      "jobTitle": newTitle,
      "jobDescription": newDesc,
      "salary": newSalary.isEmpty ? null : int.tryParse(newSalary),
      "workHours": newHours,
      "requirements": newReq,
      "isActive": true
    };

    final result = await ApiService.updateJobVacancy(body);

    setState(() => loading = false);

    if (result == true) {
      snackBar(context, "تم التعديل بنجاح");
      Navigator.pop(context, true);
    } else {
      snackBar(context, "حدث خطأ أثناء التعديل");
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
              onPressed: loading ? null : updateVacancy,
              child: loading
                  ? const LoadingDotsWidget()
                  : const Text(
                      "تأكيد",
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
                "تعديل شاغر عمل",
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