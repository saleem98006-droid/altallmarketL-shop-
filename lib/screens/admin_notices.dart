import 'package:flutter/material.dart';

class AdminNoticesScreen extends StatelessWidget {
  final String title;
  final String body;

  const AdminNoticesScreen({
    super.key,
    required this.title,
    required this.body,
  });

 @override
Widget build(BuildContext context) {
  final double screenHeight = MediaQuery.of(context).size.height;
  final double screenWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    backgroundColor: Colors.white,

    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          SizedBox(height: screenHeight * 0.18),

          // 🔵 العنوان في المنتصف
          Center(
            child: SizedBox(
              width: screenWidth * 0.90, // ← 90% من العرض (5% من كل طرف)
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.15),

          // 🔵 النص الرئيسي في المنتصف وبعرض 90%
          Expanded(
  child: Center(
    child: SizedBox(
      width: screenWidth * 0.90,
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            height: 1.5,
          ),
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