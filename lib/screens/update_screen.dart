import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OptionalUpdateScreen extends StatelessWidget {
  final String storeUrl; // رابط متجر التطبيق

  const OptionalUpdateScreen({super.key, required this.storeUrl});

  // فتح رابط المتجر (نفس طريقة JoinUsScreen)
  Future<void> _openStore() async {
    final uri = Uri.parse(storeUrl);

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      debugPrint("❌ لم يتم فتح الرابط: $storeUrl");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Icon(
                  Icons.system_update_alt_rounded,
                  size: 100,
                  color: Color(0xFF5A9BD5),
                ),

                const SizedBox(height: 20),

                const Text(
                  "تحديث جديد متوفر",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Tajawal",
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "قم بتحديث التطبيق للحصول على أفضل أداء وميزات جديدة وتحسينات في السرعة والاستقرار.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontFamily: "Tajawal",
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _openStore,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "تحديث الآن",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Tajawal",
                          color: Color(0xFF5A9BD5),
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}