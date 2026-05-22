import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../order_details_screen.dart';
import 'dart:async';
import '../../core/app_events.dart';

class CompletedOrdersTab extends StatefulWidget {
  final String searchQuery;
  const CompletedOrdersTab({super.key, required this.searchQuery});

  static List<dynamic>? cachedFinishedOrders;

  static void clearCache() {
    cachedFinishedOrders = null;
  }

  @override
  State<CompletedOrdersTab> createState() => _CompletedOrdersTabState();
}

class _CompletedOrdersTabState extends State<CompletedOrdersTab> {
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  List orders = [];
  bool isLoading = true;

  // ⭐ التحميل التدريجي
  int ordersPage = 1;
  final int ordersPageSize = 6;
  bool hasMoreOrders = true;
  bool isLoadingMore = false;

  StreamSubscription<String>? _eventSub;

  @override
  void initState() {
    super.initState();
    _loadOrders();

    _eventSub = AppEvents().stream.listen((event) {
      if (event == "refresh_orders") {
        if (mounted) {
          _loadOrders(refresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  // ⭐ التحميل التدريجي
  Future<void> _loadOrders({bool refresh = false}) async {
    if (!mounted) return;

    if (refresh) {
      CompletedOrdersTab.cachedFinishedOrders = null;
      setState(() {
        orders.clear();
        ordersPage = 1;
        hasMoreOrders = true;
        isLoading = true;
      });
    }

    if (!refresh && CompletedOrdersTab.cachedFinishedOrders != null && ordersPage == 1) {
      setState(() {
        orders = List<dynamic>.from(CompletedOrdersTab.cachedFinishedOrders!);
        isLoading = false;
        isLoadingMore = false;
        hasMoreOrders = orders.length >= ordersPageSize;
      });
      return;
    }

    if (isLoadingMore || !hasMoreOrders) return;

    setState(() => isLoadingMore = true);

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;

    final result = await ApiService.getOrdersByStatuses(
      shopId,
      ["جاهز للتوصيل", "مكتمل", "ملغي"],
      page: ordersPage,
      pageSize: ordersPageSize,
    );

    if (!mounted) return;

    if (result != null && result['data'] != null) {
      final List newOrders = result['data'];
      final int total = result['total'] ?? 0;

      setState(() {
        orders.addAll(newOrders);

        if (orders.length >= total) {
          hasMoreOrders = false;
        } else {
          ordersPage++;
        }

        isLoading = false;
        isLoadingMore = false;

        if (ordersPage == 1 || CompletedOrdersTab.cachedFinishedOrders == null) {
          CompletedOrdersTab.cachedFinishedOrders = List<dynamic>.from(orders);
        }
      });
    } else {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  List<TextSpan> _highlightMatch(String prefix, String text, String query) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (query.isEmpty || !lowerText.contains(lowerQuery)) {
      spans.add(TextSpan(text: "$prefix$text"));
      return spans;
    }

    final start = lowerText.indexOf(lowerQuery);
    final end = start + lowerQuery.length;

    spans.add(TextSpan(text: prefix));
    spans.add(TextSpan(text: text.substring(0, start)));
    spans.add(TextSpan(
      text: text.substring(start, end),
      style: const TextStyle(color: Color(0xFF5A9BD5)),
    ));
    spans.add(TextSpan(text: text.substring(end)));

    return spans;
  }

  bool _isWithoutDelivery(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'مكتمل':
        return Colors.green;
      case 'جاهز للتوصيل':
        return Color(0xFF5A9BD5);
      case 'ontheway':
        return Colors.orange;
      case 'ملغي':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_outline;
      case 'packed':
        return Icons.inventory_2_outlined;
      case 'ontheway':
        return Icons.local_shipping_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildOrdersShimmer() {
    Widget shimmerCard() {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 16, margin: const EdgeInsets.symmetric(horizontal: 80), color: Colors.white),
              const SizedBox(height: 14),
              Container(height: 12, margin: const EdgeInsets.only(right: 90, left: 24), color: Colors.white),
              const SizedBox(height: 10),
              Container(height: 12, margin: const EdgeInsets.only(right: 130, left: 24), color: Colors.white),
              const SizedBox(height: 10),
              Container(height: 12, margin: const EdgeInsets.only(right: 70, left: 24), color: Colors.white),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (_, __) => shimmerCard(),
    );
  }

  Widget _buildLoadMoreShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildOrdersShimmer();

    final filteredOrders = widget.searchQuery.trim().isEmpty
        ? orders
        : orders.where((order) {
            final name = order['customerName']?.toLowerCase() ?? '';
            final query = widget.searchQuery.toLowerCase();
            return name.contains(query);
          }).toList();

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final cardHeight = screenHeight * 0.18;
    final cardWidth = screenWidth * 0.90;

    final titleFont = screenWidth * 0.0374;
    final dateFont = screenWidth * 0.0327;
    final normalFont = screenWidth * 0.033;
    final bigFont = screenWidth * 0.0420;

    final cardPadding = cardWidth * 0.0311;
    final spaceSmall = cardHeight * 0.036;
    final spaceTiny = cardHeight * 0.012;

    if (filteredOrders.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF5A9BD5),
        onRefresh: () async => await _loadOrders(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: screenHeight * 0.7,
              child: Center(
                child: Text(
                  widget.searchQuery.trim().isEmpty
                      ? "لا توجد طلبات بالحالات المحددة"
                      : "لا توجد طلبات مطابقة للبحث",
                  style: TextStyle(fontSize: normalFont),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF5A9BD5),
      onRefresh: () async => await _loadOrders(refresh: true),
      child: ListView.builder(
        padding: EdgeInsets.all(cardPadding),
        itemCount: filteredOrders.length + 1,
        itemBuilder: (context, index) {
          // ⭐ تحميل المزيد عند الوصول للنهاية
          if (index == filteredOrders.length) {
            if (hasMoreOrders) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadOrders();
              });

              return _buildLoadMoreShimmer();
            }

            return SizedBox(height: screenHeight * 0.1);
          }

          final order = filteredOrders[index];
          final status = order['status'].toString();
          final statusColor = getStatusColor(status);
          final statusIcon = getStatusIcon(status);

          return InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(
                    shopOrderID: order['shopOrderID'],
                    unifiedOrderID: order['unifiedOrderID'],
                    subTotal: (order['subTotal'] as num).toDouble(),
                    statusSource: "جاهز للتوصيل",
                    customerName: order['customerName'] ?? "غير معروف",
                    customerNote: order['notesCustomer'] ?? "",
                    totalItems: order['totalItems'] ?? 0,
                    customerPhone: order['customerPhone'],
                  ),
                ),
              );
              if (!mounted) return;
              _loadOrders(refresh: true);
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.orange.withOpacity(0.2),
            child: Card(
              color: const Color(0xFFF6FCFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: Container(
                width: cardWidth,
                constraints: BoxConstraints(minHeight: cardHeight),
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        "الطلب ${order['unifiedOrderID']}",
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: spaceSmall),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // التاريخ والوقت
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order["createdAt"] != null
                                  ? DateTime.parse(order["createdAt"])
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0]
                                  : "",
                              style: TextStyle(
                                fontSize: dateFont,
                                fontFamily: "VladiirScript",
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: spaceTiny),
                            Text(
                              order["createdAt"] != null
                                  ? DateTime.parse(order["createdAt"])
                                      .toLocal()
                                      .toString()
                                      .split(' ')[1]
                                      .substring(0, 5)
                                  : "",
                              style: TextStyle(
                                fontSize: dateFont,
                                fontFamily: "VladiirScript",
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: spaceSmall),
                            Text(
                              _isWithoutDelivery(order["withoutDelivery"])
                                  ? "بدون توصيل"
                                  : "مع توصيل",
                              style: TextStyle(
                                fontSize: dateFont,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // معلومات الزبون والطلب
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: bigFont,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                children: _highlightMatch(
                                  "",
                                  order["customerName"] ?? "زبون غير معروف",
                                  widget.searchQuery,
                                ),
                              ),
                            ),

                            SizedBox(height: spaceSmall),

                            Text(
                              "عدد المنتجات: ${order["totalItems"] ?? 0}",
                              style: TextStyle(fontSize: normalFont),
                            ),

                            SizedBox(height: spaceSmall),

                            Text(
                              "الإجمالي: ${order["subTotal"] ?? 0} ل.س",
                              style: TextStyle(
                                fontSize: normalFont,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            SizedBox(height: spaceSmall),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(width: screenWidth * 0.014),
                                Text(
                                  "الحالة: $status",
                                  style: TextStyle(color: statusColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}