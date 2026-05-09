import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'order_details_screen.dart';

class NewOrderTab extends StatefulWidget {
  final void Function(bool hasOrders)? onOrdersLoaded;

  const NewOrderTab({super.key, this.onOrdersLoaded});

  @override
  State<NewOrderTab> createState() => _NewOrderTabState();
}

class _NewOrderTabState extends State<NewOrderTab> {
  List orders = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  // ⭐ التحميل التدريجي
  int ordersPage = 1;
  final int ordersPageSize = 6;
  bool hasMoreOrders = true;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadOrders(refresh: true);
  }

  // ⭐ التحميل التدريجي
  Future<void> _loadOrders({bool refresh = false}) async {
    if (!mounted) return;

    if (refresh) {
      setState(() {
        orders.clear();
        ordersPage = 1;
        hasMoreOrders = true;
        isLoading = true;
      });
    }

    if (isLoadingMore || !hasMoreOrders) return;

    setState(() => isLoadingMore = true);

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;

    final result = await ApiService.getOrdersByStatuses(
      shopId,
      ["جديد"],
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
      });

      widget.onOrdersLoaded?.call(orders.isNotEmpty);
    } else {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });

      widget.onOrdersLoaded?.call(false);
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

  @override
  Widget build(BuildContext context) {
    final filteredOrders = searchQuery.trim().isEmpty
        ? orders
        : orders.where((order) {
            final name = order['customerName']?.toLowerCase() ?? '';
            return name.contains(searchQuery.toLowerCase());
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

    final searchPaddingV = cardHeight * 0.084;
    final searchPaddingH = cardWidth * 0.0415;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.086),
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())

                    // ⭐ لا توجد طلبات جديدة
                    : orders.isEmpty
                        ? RefreshIndicator(
                            color: const Color(0xFF5A9BD5),
                            onRefresh: () async =>
                                await _loadOrders(refresh: true),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: screenHeight * 0.7,
                                  child: const Center(
                                    child: Text("لا توجد طلبات جديدة"),
                                  ),
                                ),
                              ],
                            ),
                          )

                        // ⭐ لا توجد نتائج للبحث
                        : filteredOrders.isEmpty &&
                                searchQuery.trim().isNotEmpty
                            ? RefreshIndicator(
                                color: const Color(0xFF5A9BD5),
                                onRefresh: () async =>
                                    await _loadOrders(refresh: true),
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: screenHeight * 0.7,
                                      child: const Center(
                                        child:
                                            Text("لا توجد طلبات مطابقة للبحث"),
                                      ),
                                    ),
                                  ],
                                ),
                              )

                            // ⭐ يوجد طلبات
                            : RefreshIndicator(
                                color: const Color(0xFF5A9BD5),
                                onRefresh: () async =>
                                    await _loadOrders(refresh: true),
                                child: ListView.builder(
                                  padding: EdgeInsets.all(cardPadding),
                                  itemCount: filteredOrders.length + 1,
                                  itemBuilder: (context, index) {
                                    // ⭐ تحميل المزيد عند النهاية
                                    if (index == filteredOrders.length) {
                                      if (hasMoreOrders) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          _loadOrders();
                                        });

                                        return const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }

                                      return SizedBox(
                                          height: screenHeight * 0.1);
                                    }

                                    final order = filteredOrders[index];

                                    return InkWell(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OrderDetailsScreen(
                                              shopOrderID:
                                                  order['shopOrderID'],
                                                  unifiedOrderID:
                                                  order['unifiedOrderID'],
                                              subTotal:
                                                  (order['subTotal'] as num)
                                                      .toDouble(),
                                              statusSource: "جديد",
                                              customerName:
                                                  order['customerName'] ??
                                                      "غير معروف",
                                              customerNote:
                                                  order['notesCustomer'] ?? "",
                                              totalItems:
                                                  order['totalItems'] ?? 0,
                                              customerPhone:
                                                  order['customerPhone'],
                                            ),
                                          ),
                                        );
                                        _loadOrders(refresh: true);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      splashColor:
                                          Colors.orange.withOpacity(0.2),
                                      child: Card(
                                        color: const Color(0xFFF6FCFC),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                        child: Container(
                                          width: cardWidth,
                                          constraints: BoxConstraints(
                                              minHeight: cardHeight),
                                          padding:
                                              EdgeInsets.all(cardPadding),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Center(
                                                child: Text(
                                                 // "الطلب ${order['shopOrderID']}",
                                               "الطلب ${order['unifiedOrderID']}",
                                                  style: TextStyle(
                                                    fontSize: titleFont,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                              SizedBox(height: spaceSmall),

                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          order["createdAt"] !=
                                                                  null
                                                              ? DateTime.parse(
                                                                      order[
                                                                          "createdAt"])
                                                                  .toLocal()
                                                                  .toString()
                                                                  .split(' ')[1]
                                                                  .substring(
                                                                      0, 5)
                                                              : "",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "VladiirScript",
                                                            fontSize: dateFont,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),

                                                      Text(
                                                        order["createdAt"] !=
                                                                null
                                                            ? DateTime.parse(order[
                                                                    "createdAt"])
                                                                .toLocal()
                                                                .toString()
                                                                .split(' ')[0]
                                                            : "",
                                                        style: TextStyle(
                                                          fontSize: dateFont,
                                                          fontFamily:
                                                              "VladiirScript",
                                                          color: Colors.grey,
                                                        ),
                                                      ),

                                                      SizedBox(
                                                          height: spaceSmall),

                                                      Text(
                                                        order["withoutDelivery"] ==
                                                                true
                                                            ? "بدون توصيل"
                                                            : "مع توصيل",
                                                        style: TextStyle(
                                                          fontSize: dateFont,
                                                          color: Colors.grey,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const Spacer(),

                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      RichText(
                                                        text: TextSpan(
                                                          style: TextStyle(
                                                            fontSize: bigFont,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.black,
                                                          ),
                                                          children:
                                                              _highlightMatch(
                                                            "",
                                                            order["customerName"] ??
                                                                "زبون غير معروف",
                                                            searchQuery,
                                                          ),
                                                        ),
                                                      ),

                                                      SizedBox(
                                                          height: spaceSmall),

                                                      Text(
                                                        "عدد المنتجات: ${order["totalItems"] ?? 0}",
                                                        style: TextStyle(
                                                            fontSize:
                                                                normalFont),
                                                      ),

                                                      SizedBox(
                                                          height: spaceSmall),

                                                      Text(
                                                        "الإجمالي: ${order["subTotal"] ?? 0} ل.س",
                                                        style: TextStyle(
                                                          fontSize: normalFont,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
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
                              ),
              ),
            ],
          ),
        ),

        // ⭐ شريط البحث العائم
        Positioned(
          top: -screenHeight * 0.0237,
          left: screenWidth * 0.0467,
          right: screenWidth * 0.0467,
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(30),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "ابحث باسم الزبون  ...",
                  suffixIcon: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Image.asset(
                      "assets/images/search.png",
                      height: screenWidth * 0.046,
                      width: screenWidth * 0.046,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: searchPaddingV,
                    horizontal: searchPaddingH,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFF5A9BD5),
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFF5A9BD5),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}