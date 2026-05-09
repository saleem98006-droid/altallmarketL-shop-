import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart'; // عدل المسار حسب مشروعك
import '../snackBar/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/loading_dots_widget.dart';
import '../../providers/router_provider.dart';

class JobVacanciesScreen extends StatefulWidget {
  const JobVacanciesScreen({super.key});

  @override
  State<JobVacanciesScreen> createState() => _JobVacanciesScreenState();
}

class _JobVacanciesScreenState extends State<JobVacanciesScreen> {
  List<dynamic> vacancies = [];
  bool loading = true;
  bool deleting = false;
  int shopId = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // تحميل shopId أولاً
    await loadShopId();
    // ثم تحميل الشواغر
    if (mounted) {
      await loadVacancies();
    }
  }

  Future<void> loadShopId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        shopId = prefs.getInt("shopId") ?? 0;
      });
    }
  }

  Future<void> loadVacancies() async {
    if (shopId == 0) return; // تأكد من أن shopId محمل
    
    final data = await ApiService.getJobVacancies(shopId);
    if (mounted) {
      setState(() {
        vacancies = data ?? [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: height * 0.05),

              // العنوان
              const Text(
                "شواغر العمل",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // البطاقات من قاعدة البيانات
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : vacancies.isEmpty
                        ? const Center(
                            child: Text(
                              "لا يوجد شواغر قم بالإضافة",
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        : ListView.builder(
                            itemCount: vacancies.length,
                            itemBuilder: (context, index) {
                              final item = vacancies[index];

                              return Card(
                                color: Colors.white, // ← غيّر اللون هنا
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(40),
  ),
  elevation: 3,
  margin: const EdgeInsets.only(bottom: 16),

  child: InkWell(
    borderRadius: BorderRadius.circular(40),

    onTap: () async {
      final result = await context.push(
        AppRoutes.editJobVacancy,
        extra: item,
      );

      if (result == true) {
        loadVacancies();
      }
    },

    onLongPress: () {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              bool deleting = false;

              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                title: const Center(
                  child: Text(
                    "هل أنت متأكد؟",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                content: const SizedBox(height: 10),
                actionsAlignment: MainAxisAlignment.spaceEvenly,
                actions: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue, width: 1.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    onPressed: deleting ? null : () => Navigator.pop(context),
                    child: const Text(
                      "إلغاء",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    onPressed: deleting
                        ? null
                        : () async {
                            setState(() => deleting = true);

                            final deleted = await ApiService.deleteJobVacancy(item["VacancyID"]);

                            if (deleted == true) {
                              Navigator.pop(context);
                              snackBar(context, "تم حذف الشاغر");
                              loadVacancies();
                            } else {
                              setState(() => deleting = false);
                              snackBar(context, "فشل حذف الشاغر");
                            }
                          },
                    child: deleting
                        ? const LoadingDotsWidget(color: Colors.red)
                        : const Text(
                            "حذف",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    },

    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

     child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    // العنوان + الوصف 
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ← كان end
        children: [
          Text(
            item["JobTitle"] ?? "بدون عنوان",
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            item["JobDescription"] ?? "",
            textAlign: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),

    const SizedBox(width: 16),

    // التاريخ + الأيقونة 
     Expanded(
       child: Column(
      crossAxisAlignment: CrossAxisAlignment.end, // ← كان start
      children: [
        Builder(
          builder: (_) {
            final createdAt = item["CreatedAt"] ?? "";

            // استخراج التاريخ فقط مهما كان شكل النص
            final dateOnly = createdAt.contains(" ")
                ? createdAt.split(" ")[0]
                : createdAt.contains("T")
                    ? createdAt.split("T")[0]
                    : createdAt;

            return Text(
              dateOnly,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        Image.asset(
          "assets/images/update.png",
          width: 28,
          height: 28,
        ),
      ],
    ),
     ),

   
  ],
),
    ),
  ),
);
                            },
                          ),
              ),

              const SizedBox(height: 10),

              // أيقونة إضافة فوق زر العودة
              Padding(
  padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.02),
  child: Align(
    alignment: Alignment.centerLeft,
    child: GestureDetector(
      onTap: () async {
        final result = await context.push(AppRoutes.addJobVacancy);

        if (result == true) {
          loadVacancies();
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(0xFF5A9BD5),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "+",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A9BD5),
            ),
          ),
        ),
      ),
    ),
  ),
),

              const SizedBox(height: 10),

              // زر العودة
              Padding(
  padding: const EdgeInsets.all(8.0),
  child: SizedBox(
    width: MediaQuery.of(context).size.width * 0.9,
    child: OutlinedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text(
        "عودة",
        style: TextStyle(
          fontFamily: "Tajawal",
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}