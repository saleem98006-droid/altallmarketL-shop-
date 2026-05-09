import 'package:flutter/material.dart';
import 'completed_orders_tab.dart';
import 'ongoing_orders_tab.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  Future<void> _refreshAll() async {
    OngoingOrdersTab.clearCache();
    CompletedOrdersTab.clearCache();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this,initialIndex: 1,);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            const SizedBox(height: 1),

            // ⭐ التبويبات الجديدة
            TabBar(
              controller: _tabController,

              labelColor: const Color(0xFF5A9BD5),
              unselectedLabelColor: Colors.grey,

              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),

              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,

              tabs: const [
                Tab(
                  child: Text(
                    "المنتهية",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
                 Tab(
                  child: Text(
                    "الجارية",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            ),

            // ⭐ محتوى التبويبات
            Expanded(
              child: RefreshIndicator(
                color: Colors.white,
                backgroundColor: const Color(0xFF5A9BD5),
                onRefresh: _refreshAll,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CompletedOrdersTab(
                      searchQuery: searchQuery,
                    ),
                    OngoingOrdersTab(
                      searchQuery: searchQuery,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ⭐ شريط البحث العائم
      Positioned(
        top: -22,
        left: 20,
        right: 20,
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
    padding: const EdgeInsets.all(10),
    child: Image.asset(
      "assets/images/search.png",
      height: 20,
      width: 20,
    ),
  ),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),

  // 🔵 الإطار عند عدم التركيز
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(
      color: Color(0xFF5A9BD5),   // 👈 لون الإطار
      width: 3,       // 👈 عرض الإطار
    ),
  ),

  // 🔵 الإطار عند التركيز
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(
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