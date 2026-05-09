

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/navigation_helper.dart'; 

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  bool _isNavigating = false;
  int _page = 1; // ✅ رقم الصفحة
  final int _pageSize = 9; // ✅ حجم الصفحة
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _markingAll = false; // لمعرفة هل تم الضغط
bool _allMarked = false;  // لتغيير اللون بعد التنفيذ

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }


String _shortenMessage(String text) {
  if (text.length <= 30) return text; // إذا النص قصير لا نلمسه

  // إذا النص طويل → نقص آخر حرفين ونضيف نقطتين
  return text.substring(0, 27) + "...";
}
  Future<void> _loadNotifications({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt("ownerId");

    if (ownerId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (refresh) {
      _page = 1;
      _hasMore = true;
      notifications.clear();
    }

    final data = await ApiService.getNotifications(
      "Shop",
      ownerId,
      page: _page,
      pageSize: _pageSize,
    );

    debugPrint("Notifications Response: $data");

    final newNotifications = data["notifications"] ?? [];

    setState(() {
  notifications.addAll(newNotifications);
  isLoading = false;
  _isLoadingMore = false;

  // 🔵 هل كل الإشعارات مقروءة؟
  _allMarked = notifications.isNotEmpty &&
      notifications.every((n) => n["isRead"] == true);

  if (newNotifications.length < _pageSize) {
    _hasMore = false;
  }
});
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications(refresh: true);
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    _loadNotifications();
  }

  Widget _buildNotificationShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FCFC),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 58,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 190,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (_, __) => _buildNotificationShimmerCard(),
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        SizedBox(height: screenHeight * 0.18), // 🔵 مسافة 5%

        // 🔵 عنوان الصفحة
        const Center(
          child: Text(
            "الإشعارات",
            style: TextStyle(
              fontFamily: "Tajawal",
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        SizedBox(height: screenHeight * 0.12), // 🔵 مسافة 5%
Padding(
  padding: EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end, // يسار
    children: [
      GestureDetector(
        onTap: () async {
          if (_markingAll) return;

          setState(() {
            _markingAll = true;
          });

          final prefs = await SharedPreferences.getInstance();
          final ownerId = prefs.getInt("ownerId");

          if (ownerId != null) {
            final result = await ApiService.markAllNotificationsAsRead(
              "Shop",
              ownerId,
            );

            // إذا نجحت العملية → غيّر اللون
            if (mounted) {
              setState(() {
                _allMarked = true;
              });
            }

            // إعادة تحميل الإشعارات
            await _refreshNotifications();
          }

          if (mounted) {
            setState(() {
              _markingAll = false;
            });
          }
        },
        child: Text(
          "تمييز الكل كمقروء",
          style: TextStyle(
            fontFamily: "Tajawal",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _allMarked ? Colors.black : Color(0xFF5A9BD5), // 🔵 يتغير بعد التنفيذ
          ),
        ),
      ),
    ],
  ),
),
 SizedBox(height: screenHeight * 0.03),

        // 🔵 باقي الصفحة داخل Scroll
        Expanded(
          child: isLoading
              ? _buildNotificationsShimmer()
              : RefreshIndicator(
                  color: Color(0xFF5A9BD5),
                  onRefresh: _refreshNotifications,
                  child: notifications.isEmpty
                      ? ListView(
                          children: const [
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("لا توجد إشعارات"),
                              ),
                            )
                          ],
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent &&
                                !_isLoadingMore) {
                              _loadMore();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: notifications.length + 1,
                            itemBuilder: (context, index) {
                              if (index == notifications.length) {
                                return _isLoadingMore
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Shimmer.fromColors(
                                          baseColor: Colors.grey.shade300,
                                          highlightColor: Colors.grey.shade100,
                                          child:
                                              _buildNotificationShimmerCard(),
                                        ),
                                      )
                                    : const SizedBox();
                              }

                              final notif = notifications[index];
                              final bool isRead = notif["isRead"] == true;

                              // 🔵 استخراج التاريخ والوقت
                              final createdAt =
                                  DateTime.tryParse(notif["createdAt"] ?? "");
                              final date = createdAt != null
                                  ? "${createdAt.year}-${createdAt.month}-${createdAt.day}"
                                  : "";
                              final time = createdAt != null
                                  ? "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}"
                                  : "";

                              return GestureDetector(
                             onTap: () async {
  if (_isNavigating) return;
  _isNavigating = true;

  final notifId = notif["notificationId"];
  final screen = notif["screen"];
  final relatedId = notif["relatedId"];
  final relatedEntity = notif["relatedEntity"]; // 🔵 نقرأ الريليتد انتتي

  // 🔵 تجهيز الداتا كما كانت في النظام القديم
  final Map<String, dynamic>? data = {
    "product": notif["product"],
    "offer": notif["offer"],
    "order": notif["order"],
    "extra": notif,
  };

  // 🔵 علّم الإشعار كمقروء
  if (notifId != null) {
    await ApiService.markNotificationAsRead(notifId);
  }

  // 🔵 إذا screen = null → استخدم relatedEntity بدلًا منه
  final effectiveScreen = screen ?? relatedEntity;

  // 🔵 التنقّل حسب effectiveScreen
  await navigateByNotification(
    context: context,
    screen: effectiveScreen,
    data: data,
    relatedId: relatedId,
  );

  // 🔵 تحديث الإشعارات بعد العودة
  await _refreshNotifications();
  _isNavigating = false;
},
                                child: Container(
  //height: MediaQuery.of(context).size.height * 0.1, // 🔵 ارتفاع 10%
  margin: const EdgeInsets.only(bottom: 20),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFF6FCFC),
    borderRadius: BorderRadius.circular(40),
    border: isRead
        ? null
        : Border.all(
            color: Colors.red,
            width: 1,
          ),
  ),

  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
   children: [
  // 🔵 اليسار سابقاً (الآن يصبح يمين): الوقت + التاريخ
 Column(
  crossAxisAlignment: CrossAxisAlignment.center, // 🔵 توسيط أفقي
  mainAxisAlignment: MainAxisAlignment.center,   // 🔵 توسيط عمودي
  children: [
    Center(
      child: Text(
        time,
        style: const TextStyle(
          fontFamily: "VladiirScript", // 🔵 الخط المطلوب
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    ),

    const SizedBox(height: 4),

    Center(
      child: Text(
        date,
        style: const TextStyle(
          fontFamily: "VladiirScript", // 🔵 الخط المطلوب
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
    ),
  ],
),

  const SizedBox(width: 12),

  // 🔵 اليمين سابقاً (الآن يصبح يسار): العنوان + الشرح
  Expanded(
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notif["title"] ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: "Tajawal",
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 5),

          // 🔵 الشرح يظهر كامل بدون قص
         Text(
  _shortenMessage(notif["message"] ?? ""),
  maxLines: 1,
  overflow: TextOverflow.visible, // نسمح له يظهر كامل السطر
  style: const TextStyle(
    fontFamily: "Tajawal",
    fontSize: 14,
    color: Colors.black54,
  ),
),
        ],
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
                ),
        ),
      ],
    ),
  );
}
}
