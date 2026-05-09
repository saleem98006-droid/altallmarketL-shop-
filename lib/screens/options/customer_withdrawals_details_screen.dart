import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class CustomerWithdrawalsDetailsScreen extends StatefulWidget {
  final int customerId;
  final String fullName;
  final String filter; // 👈 الفلتر القادم من الصفحة السابقة

  const CustomerWithdrawalsDetailsScreen({
    super.key,
    required this.customerId,
    required this.fullName,
    required this.filter,
  });

  @override
  State<CustomerWithdrawalsDetailsScreen> createState() =>
      _CustomerWithdrawalsDetailsScreenState();
}

class _CustomerWithdrawalsDetailsScreenState
    extends State<CustomerWithdrawalsDetailsScreen> {
  bool isLoading = true;
  List withdrawals = [];
  double totalAmount = 0;

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

  Widget _buildShimmerScreen(double screenWidth) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _shimmerLine(width: 180, height: 24),
                const SizedBox(height: 8),
                _shimmerLine(width: 230, height: 16),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerLine(width: double.infinity, height: 52, radius: 30),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _shimmerLine(width: 120, height: 16),
                          _shimmerLine(width: 90, height: 13),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _shimmerLine(width: 140, height: 14),
                          _shimmerLine(width: 75, height: 12),
                        ],
                      ),
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
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCustomerWithdrawals();
  }

  // 🔵 تحويل الفلتر إلى نص عربي جميل
  String getFilterLabel(String filter) {
    switch (filter) {
      case "today":
        return "اليوم";
      case "thisWeek":
        return "هذا الأسبوع";
      case "currentMonth":
        return "الشهر الحالي";
      case "lastMonth":
        return "الشهر الماضي";
      default:
        return "";
    }
  }

  Future<void> _loadCustomerWithdrawals() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;

    final result = await ApiService.getCustomerWithdrawals(
      shopId,
      widget.customerId,
      widget.filter, // 👈 إرسال الفلتر للسيرفر
    );

    if (result != null) {
      setState(() {
        withdrawals = result;
        totalAmount = withdrawals.fold<double>(
          0,
          (sum, w) => sum + ((w['amount'] ?? 0) as num).toDouble(),
        );
        isLoading = false;
      });
    } else {
      setState(() {
        withdrawals = [];
        totalAmount = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: isLoading
            ? _buildShimmerScreen(screenWidth)
            : Column(
                children: [
                  const SizedBox(height: 40),

                  // 👤 اسم الزبون + عنوان الفلتر
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          widget.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Tajawal",
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "تفاصيل مسحوبات ${getFilterLabel(widget.filter)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: "Tajawal",
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // 🧮 الإجمالي
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "إجمالي المسحوبات: $totalAmount",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Tajawal",
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 📋 قائمة السجلات
                  Expanded(
                    child: withdrawals.isEmpty
                        ? const Center(
                            child: Text(
                              "لا توجد مسحوبات لهذا الزبون ضمن الفلترة المختارة",
                              style: TextStyle(fontFamily: "Tajawal"),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: withdrawals.length,
                            itemBuilder: (context, index) {
                              final w = withdrawals[index];

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                   borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 🔵 السطر الأول: المبلغ + التاريخ
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "المبلغ: ${w['amount']}",
          style: const TextStyle(
            fontSize: 16,
            fontFamily: "Tajawal",
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          w['createdAt'].toString().split('T')[0], // التاريخ فقط
          style: const TextStyle(
            fontSize: 13,
            fontFamily: "Tajawal",
            color: Colors.grey,
          ),
        ),
      ],
    ),

    const SizedBox(height: 6),

    // 🔵 السطر الثاني: عدد المنتجات + الوقت
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "عدد المنتجات: ${w['totalItems']}",
          style: const TextStyle(
            fontSize: 14,
            fontFamily: "Tajawal",
          ),
        ),
        Text(
          w['createdAt'].toString().split('T')[1].split('.')[0], // الوقت فقط
          style: const TextStyle(
            fontSize: 12,
            fontFamily: "Tajawal",
            color: Colors.grey,
          ),
        ),
      ],
    ),
  ],
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