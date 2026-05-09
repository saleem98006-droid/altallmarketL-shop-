import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/api_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isLoading = true;
  List<dynamic> _infoList = [];

  Widget _shimmerLine({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildAboutShimmer() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                const SizedBox(height: 30),
                _shimmerLine(width: 90, height: 26),
                const SizedBox(height: 10),
                _shimmerLine(width: 180, height: 24),
                const SizedBox(height: 16),
                _shimmerLine(width: screenWidth * 0.8, height: 1, radius: 1),
                const SizedBox(height: 4),
              ],
            );
          }

          return Center(
            child: SizedBox(
              width: screenWidth * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerLine(width: 140, height: 20),
                  const SizedBox(height: 10),
                  _shimmerLine(width: screenWidth * 0.7, height: 14),
                  const SizedBox(height: 8),
                  _shimmerLine(width: screenWidth * 0.62, height: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAppInfo();
  }
Future<void> _fetchAppInfo() async {
  try {
    // ✅ أولاً: جلب سجل من جدول Appvirsion (إصدار التطبيق)
    final versionResult = await ApiService.getAppVersionByName("**اسم التطبيق:** TM_SHOP");
    print("📦 الرد من السيرفر (إصدار التطبيق): $versionResult");

    // ✅ ثانياً: جلب معلومات التطبيق كما هو
    final result = await ApiService.getAppInfo(language: "ar");
    print("📦 الرد من السيرفر (معلومات التطبيق): $result");

    if (mounted) {
      setState(() {
        _infoList = [];

        // إذا نجح جدول الإصدار نضيفه كسجل واحد منسق
        if (versionResult != null && versionResult["success"] == true) {
          final versionData = versionResult["data"];

          if (versionData is List && versionData.isNotEmpty) {
            final v = versionData.first; // ✅ أول سجل من القائمة
            _infoList.add({
              "title": "إصدار التطبيق",
              "content":
                  "${v["appname"]}\n${v["virsion"]}\n${v["datevirsion"]}"
            });
          }
        }

        // إذا نجح الجدول الأساسي نضيفه بعده
        if (result != null && result["success"] == true) {
          _infoList.addAll(result["data"]);
        }

        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ أثناء جلب المعلومات: $e")),
      );
    }
  }
}
 

  // 🔹 دالة لمعالجة النصوص: إزالة ** وتحويلها إلى Bold + استبدال الشرطات بنقاط
  List<TextSpan> _parseContent(String content) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    // استبدال الشرطات بنقاط
    content = content.replaceAll(RegExp(r'^\s*-\s*', multiLine: true), '• ');

    for (final match in regex.allMatches(content)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
        ));
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ خلفية بيضاء
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? _buildAboutShimmer()
            : _infoList.isEmpty
                ? const Center(child: Text("لا توجد معلومات متاحة"))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _infoList.length + 1, // ✅ +1 للهيدر
                    separatorBuilder: (context, index) {
                      if (index == 0) {
                        return const SizedBox(height: 0); // لا خط قبل الهيدر
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 1,
                           // color: Colors.grey.shade400, // ✅ خط رمادي بين السجلات
                           color: Colors.black,
                          ),
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // ✅ الهيدر
                        return Column(
                          children: [
                            const SizedBox(height: 30),
                            const Text(
                              "حول",
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "ALTALL_MARKET",
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: 1,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }

                      final item = _infoList[index - 1];
                      return Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8, // ✅ عرض 80%
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["title"] ?? "بدون عنوان",
                                style: const TextStyle(
                                  fontFamily: "Tajawal",
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5A9BD5), // ✅ العنوان أزرق
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: "Tajawal",
                                    fontSize: 18,
                                    height: 1.6, // ✅ مسافة بين الأسطر
                                    color: Colors.black,
                                  ),
                                  children: _parseContent(
                                    item["content"] ?? "لا يوجد محتوى",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}