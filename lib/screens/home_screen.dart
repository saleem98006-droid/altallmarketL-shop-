import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'notifications/notifications_page.dart';

// استدعاء التبويبات
import 'home0/home_tab_new.dart';
import 'orders/orders_tab.dart';
import 'myAccount/account_tab.dart';
import 'options/options_tab.dart';
import 'new_order_tab.dart';
import '../services/api_service.dart';
import '../providers/account_provider.dart';
import 'myAccount/inactive_screen.dart';
import '../providers/router_provider.dart';
import '../core/notification_handlers.dart';
 

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTabIndex; // 🔵 تمت إضافتها

  const HomeScreen({
    super.key,
    this.initialTabIndex = 0, // 🔵 القيمة الافتراضية
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  static const Color kBlue = Color(0xFF5a9bd5);
  bool get isMiddleActive => selectedIndex == 2;

  late int selectedIndex;
  bool hasNewOrders = false;
  bool hasNewNotifications = false;
  String searchQuery = "";

  void _selectIndex(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedIndex = widget.initialTabIndex;
    _checkNewOrders();
    _checkNewNotifications();
    newOrderNotificationTick.addListener(_handleNewOrderNotificationTick);
    notificationsTick.addListener(_handleNotificationsTick);
  }
  

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        widget.initialTabIndex != selectedIndex) {
      setState(() {
        selectedIndex = widget.initialTabIndex;
      });
    }
  }

  void _handleNewOrderNotificationTick() {
    if (!mounted) return;
    setState(() {
      hasNewOrders = true;
    });
    _checkNewOrders();
  }

  void _handleNotificationsTick() {
    if (!mounted) return;
    _checkNewNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNewOrders();
      _checkNewNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    newOrderNotificationTick.removeListener(_handleNewOrderNotificationTick);
    notificationsTick.removeListener(_handleNotificationsTick);
    super.dispose();
  }

  Future<void> _checkNewOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;
    final result = await ApiService.getOrdersByStatuses(shopId, ["جديد"]);
    if (!mounted) return;

    setState(() {
      hasNewOrders =
          result != null && result['data'] != null && result['data'].isNotEmpty;
    });
  }

  Future<void> _checkNewNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt("ownerId");

    if (ownerId == null) {
      setState(() {
        hasNewNotifications = false;
      });
      return;
    }

    final data = await ApiService.getNotifications(
      "Shop",
      ownerId,
      page: 1,
      pageSize: 5,
    );

    final list = data["notifications"] ?? [];

    final bool hasUnread = list.any((n) => n["isRead"] == false);

    setState(() {
      hasNewNotifications = hasUnread;
    });
  }

  List<Widget> get pages => [
        const HomeTabNew(),
        const OrdersTab(),
        NewOrderTab(
          onOrdersLoaded: (bool hasOrders) {
            setState(() {
              hasNewOrders = hasOrders;
            });
          },
        ),
        const AccountTab(),
        const OptionsTab(),
      ];

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final accountState = ref.watch(accountProvider);

    if (!accountState.isActive) {
      Future.microtask(() {
        context.go(AppRoutes.inactive);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: topPadding),
            height: 90 + topPadding,
            color: kBlue,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text(
                    "Shop",
                    style: TextStyle(
                      fontFamily: "VladiirScript",
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Image.asset(
                            "assets/images/notification1.png",
                            height: 28,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            );
                            _checkNewNotifications();
                          },
                        ),
                        if (hasNewNotifications)
                          Positioned(
                            top: 5,
                            right: 6,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildInnerScaffold()),
        ],
      ),
    );
  }

  Widget _buildInnerScaffold() {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: isKeyboardOpen
          ? const SizedBox.shrink()
          : MediaQuery.removeViewInsets(
              removeBottom: true,
              context: context,
              child: SizedBox(
                height: 95,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(color: Colors.transparent),
                    ),

                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 75,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: const BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(40),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: selectedIndex == 4
                                    ? Image.asset(
                                        "assets/images/options2.png",
                                        height: 28,
                                        color: Colors.white,
                                      )
                                    : Image.asset(
                                        "assets/images/options1.png",
                                        height: 28,
                                        color: Colors.white,
                                      ),
                                onPressed: () => _selectIndex(4),
                              ),
                            IconButton(
                              icon: Image.asset(
                                selectedIndex == 3
                                    ? "assets/images/myAccount2.png"
                                    : "assets/images/myAccount1.png",
                                height: 28,
                              ),
                              onPressed: () => _selectIndex(3),
                            ),

                            const SizedBox(width: 55),

                            IconButton(
                              icon: Image.asset(
                                selectedIndex == 1
                                    ? "assets/images/order2.png"
                                    : "assets/images/order1.png",
                                height: 28,
                              ),
                              onPressed: () => _selectIndex(1),
                            ),

                            IconButton(
                              icon: Image.asset(
                                selectedIndex == 0
                                    ? "assets/images/home2.png"
                                    : "assets/images/home1.png",
                                height: 28,
                              ),
                              onPressed: () => _selectIndex(0),
                            ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _selectIndex(2),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: selectedIndex == 2
                                ? Container(
                                    key: const ValueKey("big"),
                                    width: 85,
                                    height: 85,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: hasNewOrders ? Colors.red : kBlue,
                                        width: 5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        "assets/images/fast_cart.png",
                                        color: kBlue,
                                        height: 35,
                                      ),
                                    ),
                                  )
                                : Container(
                                    key: const ValueKey("small"),
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kBlue,
                                      border: Border.all(
                                        color: hasNewOrders
                                            ? Colors.red
                                            : Colors.white,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}