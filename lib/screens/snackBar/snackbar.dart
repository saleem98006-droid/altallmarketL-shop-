import 'package:flutter/material.dart';

void snackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 14, // حجم النص الأساسي
          fontFamily: "Tajawal",
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.black,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        // ✅ أصغر عرض 40% من الشاشة
        left: MediaQuery.of(context).size.width * 0.20,
        right: MediaQuery.of(context).size.width * 0.20,
        bottom: MediaQuery.of(context).size.height * 0.20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(
          color: Color(0xFF5A9BD5), 
          width: 0,
        ),
      ),
    ),
  );
}