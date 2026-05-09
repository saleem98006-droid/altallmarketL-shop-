import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../providers/router_provider.dart';

class CustomerWithdrawalsScreen extends StatefulWidget {
  const CustomerWithdrawalsScreen({super.key});

  @override
  State<CustomerWithdrawalsScreen> createState() => _CustomerWithdrawalsScreenState();
}

class _CustomerWithdrawalsScreenState extends State<CustomerWithdrawalsScreen> {
  bool isLoading = true;
  List withdrawals = [];
  String? loadError;

  String selectedFilter = "currentMonth";

  @override
  void initState() {
    super.initState();
    _loadWithdrawals(selectedFilter);
  }

  Future<void> _loadWithdrawals(String filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? 0;

      final result = await ApiService.getWithdrawalsSummary(shopId, filter);

      if (!mounted) return;
      setState(() {
        withdrawals = result ?? [];
        loadError = null;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        withdrawals = [];
        loadError = "حدث خطأ أثناء جلب البيانات";
        isLoading = false;
      });
      debugPrint("❌ CustomerWithdrawalsScreen load error: $e");
    }
  }

  Widget _buildFilterButton({
    required String keyValue,
    required String label,
    required VoidCallback onTap,
    double fontSize = 12,
  }) {
    final bool isSelected = selectedFilter == keyValue;

    return Expanded(
      child: SizedBox(
        height: 36,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isSelected ? const Color(0xFF5A9BD5) : Colors.grey,
              width: 1.5,
            ),
            backgroundColor: isSelected ? const Color(0xFF5A9BD5) : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: "Tajawal",
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildShimmerScreen(double screenHeight, double screenWidth) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.05),
            _shimmerLine(width: 170, height: 24),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == 3 ? 0 : 6),
                      child: _shimmerLine(width: double.infinity, height: 36, radius: 20),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _shimmerLine(width: 90, height: 14)),
                  Expanded(child: Align(alignment: Alignment.centerLeft, child: _shimmerLine(width: 90, height: 14))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: 7,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _shimmerLine(width: screenWidth * 0.35, height: 16)),
                        Expanded(child: Align(alignment: Alignment.centerLeft, child: _shimmerLine(width: 70, height: 16))),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _shimmerLine(width: screenWidth * 0.9, height: 44, radius: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: isLoading
          ? _buildShimmerScreen(screenHeight, screenWidth)
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.05),

                  const Text(
                    "مسحوبات الزبائن",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Tajawal",
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // 🔵 الفلاتر
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        _buildFilterButton(
                          keyValue: "today",
                          label: "اليوم",
                          onTap: () {
                            setState(() {
                              selectedFilter = "today";
                              isLoading = true;
                            });
                            _loadWithdrawals("today");
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterButton(
                          keyValue: "thisWeek",
                          label: "هذا الأسبوع",
                          onTap: () {
                            setState(() {
                              selectedFilter = "thisWeek";
                              isLoading = true;
                            });
                            _loadWithdrawals("thisWeek");
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterButton(
                          keyValue: "currentMonth",
                          label: "الشهر الحالي",
                          onTap: () {
                            setState(() {
                              selectedFilter = "currentMonth";
                              isLoading = true;
                            });
                            _loadWithdrawals("currentMonth");
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterButton(
                          keyValue: "lastMonth",
                          label: "الشهر الماضي",
                          fontSize: 10,
                          onTap: () {
                            setState(() {
                              selectedFilter = "lastMonth";
                              isLoading = true;
                            });
                            _loadWithdrawals("lastMonth");
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🏷️ شريط العناوين
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            "اسم الزبون",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: "Tajawal",
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "مقدار السحب",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: "Tajawal",
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 📋 القائمة
                  Expanded(
                    child: loadError != null
                        ? Center(
                            child: Text(
                              loadError!,
                              style: const TextStyle(
                                fontFamily: "Tajawal",
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : withdrawals.isEmpty
                            ? const Center(
                                child: Text(
                                  "لا توجد بيانات ضمن الفلترة المختارة",
                                  style: TextStyle(fontFamily: "Tajawal"),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                itemCount: withdrawals.length,
                                itemBuilder: (context, index) {
                                  final w = withdrawals[index];
                                  final fullName = (w['fullName'] != null &&
                                          w['fullName'].toString().trim().isNotEmpty)
                                      ? w['fullName'].toString()
                                      : "بدون اسم";

                                  final total = (w['totalWithdrawals'] ?? 0).toString();

                                  return InkWell(
                                    onTap: () {
                                      final customerId =
                                          w['customerID'] ?? w['customerId'] ?? 0;

                                      context.push(
                                        AppRoutes.customerWithdrawalsDetails,
                                        extra: {
                                          'customerId': customerId,
                                          'fullName': fullName,
                                          'filter': selectedFilter,
                                        },
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fullName,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontFamily: "Tajawal",
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              total,
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontFamily: "Tajawal",
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF5A9BD5),
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
                ],
              ),
            ),
    );
  }
}