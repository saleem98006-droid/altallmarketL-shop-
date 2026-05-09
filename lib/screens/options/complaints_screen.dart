import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../snackBar/snackbar.dart';
import '../../widgets/loading_dots_widget.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ استرجاع ownerId من التخزين
  Future<int?> _getownerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ownerId');
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final ownerId = await _getownerId();
      if (ownerId == null) {
         snackBar(context,"لم يتم العثور على رقمك");
        return;
      }

      final result = await ApiService.addComplaint(
        submittedByType: "Shop", 
        submittedById: ownerId,
        title: "شكوى جديدة",
        message: text,
      );

      if (result != null && result["success"] == true) {
        if (!mounted) return;
         snackBar(context,"تم ارسال الشكوى بنجاح");

        _controller.clear();
        // نبقى في نفس الصفحة بعد الإرسال الناجح
      } else {
          if (!mounted) return;
          snackBar(context,"حدث خطأ اثناء الارسال..اعد المحاولة");
      }
    } catch (e) {
      if (!mounted) return;
       snackBar(context,"خطأ: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  
 @override
Widget build(BuildContext context) {
  const Color blue = Color(0xFF1976D2);

  return Scaffold(
    backgroundColor: Colors.white,
    resizeToAvoidBottomInset: true, // ✅ يسمح بتكيف الواجهة مع الكيبورد
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            const Text(
              'تكلم معنا ولا تتكلم علينا',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: "Tajawal",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'لا تتردد أبداً',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontFamily: "Tajawal",
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),

            // ✅ مربع الكتابة بارتفاع 30% وزوايا 40
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'اكتب شكواك هنا...',
                  hintTextDirection: TextDirection.rtl,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 1.5),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5A9BD5), width: 2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                style: const TextStyle(fontFamily: "Tajawal"),
              ),
            ),

          
          ],
        ),
      ),
    ),

    // ✅ زر الإرسال خارج السكرول ومثبت بالأسفل
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: _isLoading ? null : _submit,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            side: BorderSide(color: Color(0xFF5A9BD5), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isLoading
              ? const LoadingDotsWidget()
              : const Text(
                  'إرسال',
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
  );
}
 
}