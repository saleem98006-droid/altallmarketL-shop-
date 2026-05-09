import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    //fontFamily: 'Tajawal',
    primaryColor: const Color(0xFF5A9BD5),
    scaffoldBackgroundColor: Colors.white,

    useMaterial3: true, // مهم جدًا لتفعيل الثيم الجديد

datePickerTheme: DatePickerThemeData(
  backgroundColor: Colors.white,
  headerBackgroundColor: const Color(0xFF5A9BD5),
  headerForegroundColor: Colors.white,

  todayForegroundColor: WidgetStateProperty.all(const Color(0xFF5A9BD5)),
  todayBackgroundColor: WidgetStateProperty.all(
    const Color(0xFF5A9BD5).withOpacity(0.2),
  ),

  dayForegroundColor: WidgetStateProperty.all(Colors.black),
  dayOverlayColor: WidgetStateProperty.all(
    const Color(0xFF5A9BD5).withOpacity(0.1),
  ),

  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
),

timePickerTheme: TimePickerThemeData(
  backgroundColor: Colors.white,

  hourMinuteColor: const Color(0xFF5A9BD5).withOpacity(0.1),
  hourMinuteTextColor: const Color(0xFF5A9BD5),

  dialHandColor: const Color(0xFF5A9BD5),
  dialBackgroundColor: const Color(0xFF5A9BD5).withOpacity(0.1),

  entryModeIconColor: const Color(0xFF5A9BD5),

  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
),

    // ================================
    //  🎯 تنسيق الحقول
    // ================================
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(
        fontFamily: 'Tajawal',
        color: Colors.black54,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF5A9BD5), width: 2.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF5A9BD5), width: 3.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF5A9BD5), width: 1),
      ),
    ),

    // ================================
    //  🔲 ثيم OutlinedButton
    // ================================
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: MaterialStateProperty.all(
          const BorderSide(color: Color(0xFF5A9BD5), width: 3),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(MaterialState.pressed)) {
              return const Color(0xFF5A9BD5);
            }
            return Colors.white;
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.white;
            }
            return Colors.black;
          },
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 16),
        ),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    ),
  );
}
