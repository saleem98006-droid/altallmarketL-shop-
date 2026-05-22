import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
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
  static const String _homeTutorialDoneKey = 'shop_home_tutorial_done_v1';
  static const bool _showTutorialEveryOpen = false;
  bool get isMiddleActive => selectedIndex == 2;

  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _homeTabKey = GlobalKey();
  final GlobalKey _ordersTabKey = GlobalKey();
  final GlobalKey _newTabKey = GlobalKey();
  final GlobalKey _accountTabKey = GlobalKey();
  final GlobalKey _optionsTabKey = GlobalKey();

  TutorialCoachMark? _tutorialCoachMark;
  bool _isTutorialScheduled = false;

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
    _maybeStartTutorial();
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
    _tutorialCoachMark?.finish();
    WidgetsBinding.instance.removeObserver(this);
    newOrderNotificationTick.removeListener(_handleNewOrderNotificationTick);
    notificationsTick.removeListener(_handleNotificationsTick);
    super.dispose();
  }

  Future<void> _maybeStartTutorial() async {
    if (_isTutorialScheduled || !mounted) return;
    _isTutorialScheduled = true;

    final prefs = await SharedPreferences.getInstance();
    final wasShown = prefs.getBool(_homeTutorialDoneKey) ?? false;
    final shouldShow = _showTutorialEveryOpen || !wasShown;
    if (!shouldShow) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _createTutorial();
    });

    if (!_showTutorialEveryOpen) {
      await prefs.setBool(_homeTutorialDoneKey, true);
    }
  }

  Widget _buildTutorialMessage({
    required String title,
    required String description,
  }) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                height: 1.45,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TargetFocus> _buildTutorialTargets() {
    return <TargetFocus>[
      TargetFocus(
        identify: 'notifications',
        keyTarget: _notificationsKey,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        radius: 22,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => _buildTutorialMessage(
              title: 'الإشعارات',
              description: 'أي تنبيه مهم للحساب أو الطلبات يظهر هنا',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home-tab',
        keyTarget: _homeTabKey,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        radius: 20,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => _buildTutorialMessage(
              title: 'الرئيسية',
              description: 'واجهة المتجر الرئيسية لعرض المحتوى',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'orders-tab',
        keyTarget: _ordersTabKey,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        radius: 20,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => _buildTutorialMessage(
              title: 'طلباتي',
              description: 'هنا تتابع الطلبات الجارية والمكتملة',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'new-orders-tab',
        keyTarget: _newTabKey,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        radius: 30,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => _buildTutorialMessage(
              title: 'جديد',
              description: 'هذا الزر يعرض الطلبات الجديدة مباشرة',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'account-tab',
        keyTarget: _accountTabKey,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        radius: 20,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => _buildTutorialMessage(
              title: 'حسابي',
              description: 'لإدارة بيانات المحل ومعلومات الحساب',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'options-tab',
        keyTarget: _optionsTabKey,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        radius: 20,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => _buildTutorialMessage(
              title: 'خيارات',
              description: 'خدمات وإجراءات إضافية خاصة بالمتجر',
            ),
          ),
        ],
      ),
    ];
  }

  bool _isTargetReady(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return false;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return false;

    return renderObject.attached &&
        renderObject.hasSize &&
        renderObject.size.width > 0 &&
        renderObject.size.height > 0;
  }

  bool _areTutorialTargetsReady() {
    return <GlobalKey>[
      _notificationsKey,
      _homeTabKey,
      _ordersTabKey,
      _newTabKey,
      _accountTabKey,
      _optionsTabKey,
    ].every(_isTargetReady);
  }

  void _createTutorial({int attempt = 0}) {
    if (!mounted) return;

    if (!_areTutorialTargetsReady()) {
      if (attempt < 12) {
        Future.delayed(
          const Duration(milliseconds: 250),
          () => _createTutorial(attempt: attempt + 1),
        );
      }
      return;
    }

    _tutorialCoachMark = TutorialCoachMark(
      targets: _buildTutorialTargets(),
      colorShadow: Colors.black,
      opacityShadow: 0.82,
      hideSkip: true,
      pulseEnable: true,
      pulseAnimationDuration: const Duration(milliseconds: 700),
      focusAnimationDuration: const Duration(milliseconds: 450),
      unFocusAnimationDuration: const Duration(milliseconds: 260),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _tutorialCoachMark?.show(context: context);
    });
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
                    key: _notificationsKey,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: const BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(40),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: InkWell(
                                  key: _optionsTabKey,
                                  onTap: () => _selectIndex(4),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 6),
                                      Image.asset(
                                        selectedIndex == 4
                                            ? "assets/images/options2.png"
                                            : "assets/images/options1.png",
                                        height: 26,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "خيارات",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: selectedIndex == 4
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  key: _accountTabKey,
                                  onTap: () => _selectIndex(3),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 6),
                                      Image.asset(
                                        selectedIndex == 3
                                            ? "assets/images/myAccount2.png"
                                            : "assets/images/myAccount1.png",
                                        height: 26,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "حسابي",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: selectedIndex == 3
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 80),
                              Expanded(
                                child: InkWell(
                                  key: _ordersTabKey,
                                  onTap: () => _selectIndex(1),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 6),
                                      Image.asset(
                                        selectedIndex == 1
                                            ? "assets/images/order2.png"
                                            : "assets/images/order1.png",
                                        height: 26,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "طلباتي",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: selectedIndex == 1
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  key: _homeTabKey,
                                  onTap: () => _selectIndex(0),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 6),
                                      Image.asset(
                                        selectedIndex == 0
                                            ? "assets/images/home2.png"
                                            : "assets/images/home1.png",
                                        height: 26,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "الرئيسية",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: selectedIndex == 0
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          key: _newTabKey,
                          children: [
                            AnimatedSwitcher(
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
                                  : InkWell(
                                      key: const ValueKey("small"),
                                      onTap: () => _selectIndex(2),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 30,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: kBlue,
                                          border: Border.all(
                                            color: hasNewOrders
                                                ? Colors.red
                                                : Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            if (selectedIndex != 2)
                              const Text(
                                "جديد",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
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