import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/monthly_statement_provider.dart';

class MonthlyDuesScreen extends ConsumerStatefulWidget {
  const MonthlyDuesScreen({super.key});

  @override
  ConsumerState<MonthlyDuesScreen> createState() => _MonthlyDuesScreenState();
}

class _MonthlyDuesScreenState extends ConsumerState<MonthlyDuesScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedMonth;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '--';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return '${parsed.year}/${parsed.month}/${parsed.day}';
  }

  Widget _metricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color background,
    required Color iconColor,
    required Color valueColor,
    required Color labelColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: valueColor,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '--';
    return '${date.year}/${date.month}/${date.day}';
  }

  String _monthName(int month) {
    const months = [
      'كانون الثاني',
      'شباط',
      'آذار',
      'نيسان',
      'أيار',
      'حزيران',
      'تموز',
      'آب',
      'أيلول',
      'تشرين الأول',
      'تشرين الثاني',
      'كانون الأول',
    ];
    if (month < 1 || month > 12) return '$month';
    return months[month - 1];
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF57636C)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Color(0xFF57636C),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101213),
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E3E7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'اختر الشهر',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: 12,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == _selectedMonth;
                    return ListTile(
                      title: Text(
                        _monthName(month),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF5A9BD5))
                          : null,
                      onTap: () => Navigator.of(context).pop(month),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != _selectedMonth) {
      setState(() => _selectedMonth = selected);
    }
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: _buildPickerField(
            label: 'الشهر',
            value: _monthName(_selectedMonth),
            onTap: _showMonthSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildStatementBody(MonthlyStatementData data, {required double topPadding}) {
    final movementItems = data.accountMovements;

    return RefreshIndicator(
      color: const Color(0xFF5A9BD5),
      backgroundColor: Colors.white,
      onRefresh: () async {
        final request = MonthlyStatementRequest(
          shopId: data.shopId,
          month: _selectedMonth,
        );
        await ref.refresh(monthlyStatementProvider(request).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              'تفاصيل المستحقات',
              style: TextStyle(
                color: Color(0xFF101213),
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              'المبيعات و النسبة',
              style: TextStyle(
                color: Color(0xFF57636C),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterBar(),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _metricCard(
                icon: Icons.payments,
                value: data.totalWithdrawals.toStringAsFixed(1),
                label: 'إجمالي المبيعات',
                background: const Color(0xFF5A9BD5),
                iconColor: Colors.white,
                valueColor: Colors.white,
                labelColor: Colors.white,
              ),
              _metricCard(
                icon: Icons.percent,
                value: data.commissionPercent
                    .toStringAsFixed(data.commissionPercent % 1 == 0 ? 0 : 2),
                label: 'النسبة',
                background: const Color(0xFFF1F4F8),
                iconColor: const Color(0xFF101213),
                valueColor: const Color(0xFF101213),
                labelColor: const Color(0xFF57636C),
              ),
              _metricCard(
                icon: Icons.payments_outlined,
                value: data.commissionValue.toStringAsFixed(1),
                label: 'العمولة المستحقة',
                background: const Color(0xFFF1F4F8),
                iconColor: const Color(0xFF101213),
                valueColor: const Color(0xFF101213),
                labelColor: const Color(0xFF57636C),
              ),
              _metricCard(
                icon: Icons.pie_chart_rounded,
                value: data.netBalance.toStringAsFixed(1),
                label: 'صافي الحساب',
                background: const Color(0xFFF1F4F8),
                iconColor: const Color(0xFF101213),
                valueColor: const Color(0xFF101213),
                labelColor: const Color(0xFF57636C),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              'حركة الحساب',
              style: TextStyle(
                color: Color(0xFF57636C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (movementItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'لا توجد حركة حساب ضمن الشهر المحدد',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          else
            ...movementItems.map((item) {
              final color = item.isCredit ? Colors.red : const Color(0xFF5A9BD5);
              final title = item.notes.trim().isNotEmpty
                  ? item.notes
                  : (item.isCredit ? 'دفعة على الحساب' : 'دفعة مستحقة');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF1F4F8),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.amount.toStringAsFixed(2),
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF101213),
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(item.date),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: Color(0xFF57636C),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    BorderRadius? radius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final t = _shimmerController.value;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (2.0 * t), -0.2),
              end: Alignment(1.0 + (2.0 * t), 0.2),
              colors: const [
                Color(0xFFE9EDF3),
                Color(0xFFF6F8FB),
                Color(0xFFE9EDF3),
              ],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBody(double topPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _shimmerBox(height: 28, width: 180, radius: BorderRadius.circular(8)),
          const SizedBox(height: 8),
          _shimmerBox(height: 16, width: 120, radius: BorderRadius.circular(8)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _shimmerBox(height: 56)),
              const SizedBox(width: 10),
              Expanded(child: _shimmerBox(height: 56)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (_) => _shimmerBox(height: 150, radius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 14),
          _shimmerBox(height: 18, width: 100, radius: BorderRadius.circular(8)),
          const SizedBox(height: 10),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF1F4F8),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _shimmerBox(
                      height: 26,
                      width: 80,
                      radius: BorderRadius.circular(8),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _shimmerBox(
                          height: 16,
                          width: 150,
                          radius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 6),
                        _shimmerBox(
                          height: 12,
                          width: 95,
                          radius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(currentShopIdProvider);
    final topSpacing = MediaQuery.sizeOf(context).height * 0.07;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: shopAsync.when(
          loading: () => _buildShimmerBody(topSpacing),
          error: (_, __) => const Center(
            child: Text(
              'تعذر قراءة بيانات المحل',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.red),
            ),
          ),
          data: (shopId) {
            if (shopId <= 0) {
              return const Center(
                child: Text(
                  'رقم المحل غير متوفر',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.red),
                ),
              );
            }

            final request = MonthlyStatementRequest(
              shopId: shopId,
              month: _selectedMonth,
            );

            final statementAsync = ref.watch(monthlyStatementProvider(request));

            return statementAsync.when(
              loading: () => _buildShimmerBody(topSpacing),
              error: (_, __) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'تعذر تحميل كشف المستحقات',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(monthlyStatementProvider(request)),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                ],
              ),
              data: (data) => _buildStatementBody(data, topPadding: topSpacing),
            );
          },
        ),
      ),
    );
  }
}
