import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'notifications/notifications_page.dart';

import 'home0/home_tab_new.dart';
import 'orders/orders_tab.dart';
import 'myAccount/account_tab.dart';
import 'options/options_tab.dart';
import 'new_order_tab.dart';
import '../services/api_service.dart';
import '../providers/account_provider.dart';
import '../providers/router_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const HomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const Color kBlue = Color(0xFF5a9bd5);

  late int selectedIndex;
  bool hasNewOrders = false;
  bool hasNewNotifications = false;

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

  void _selectIndex(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex;
    _checkNewOrders();
    _checkNewNotifications();
  }

  Future<void> _checkNewOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;
    final result = await ApiService.getOrdersByStatuses(shopId, ['جديد']);
    if (!mounted) return;

    setState(() {
      hasNewOrders = result != null &&
          result['data'] != null &&
          (result['data'] as List).isNotEmpty;
    });
  }

  Future<void> _checkNewNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('ownerId');

    if (ownerId == null) {
      setState(() {
        hasNewNotifications = false;
      });
      return;
    }

    final data = await ApiService.getNotifications(
      'Shop',
      ownerId,
      page: 1,
      pageSize: 5,
    );

    final list = (data['notifications'] ?? []) as List;
    final hasUnread = list.any((n) => n['isRead'] == false);

    if (!mounted) return;
    setState(() {
      hasNewNotifications = hasUnread;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final accountState = ref.watch(accountProvider);

    if (!accountState.isActive) {
      Future.microtask(() => context.go(AppRoutes.inactive));
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
                    'Shop',
                    style: TextStyle(
                      fontFamily: 'VladiirScript',
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
                            'assets/images/notification1.png',
                            height: 28,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
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
          Expanded(child: _buildInnerScaffold(context)),
        ],
      ),
    );
  }

  Widget _buildInnerScaffold(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
                                icon: Image.asset(
                                  selectedIndex == 4
                                      ? 'assets/images/options2.png'
                                      : 'assets/images/options1.png',
                                  height: 28,
                                  color: Colors.white,
                                ),
                                onPressed: () => _selectIndex(4),
                              ),
                              IconButton(
                                icon: Image.asset(
                                  selectedIndex == 3
                                      ? 'assets/images/myAccount2.png'
                                      : 'assets/images/myAccount1.png',
                                  height: 28,
                                ),
                                onPressed: () => _selectIndex(3),
                              ),
                              const SizedBox(width: 55),
                              IconButton(
                                icon: Image.asset(
                                  selectedIndex == 1
                                      ? 'assets/images/order2.png'
                                      : 'assets/images/order1.png',
                                  height: 28,
                                ),
                                onPressed: () => _selectIndex(1),
                              ),
                              IconButton(
                                icon: Image.asset(
                                  selectedIndex == 0
                                      ? 'assets/images/home2.png'
                                      : 'assets/images/home1.png',
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
                                    key: const ValueKey('big'),
                                    width: 85,
                                    height: 85,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: hasNewOrders ? Colors.red : kBlue,
                                        width: 5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/images/fast_cart.png',
                                        color: kBlue,
                                        height: 35,
                                      ),
                                    ),
                                  )
                                : Container(
                                    key: const ValueKey('small'),
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kBlue,
                                      border: Border.all(
                                        color: hasNewOrders ? Colors.red : Colors.white,
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
