import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../snackBar/snackbar.dart';
import '../../widgets/loading_dots_widget.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({Key? key}) : super(key: key);

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
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
      if (mounted) snackBar(context, "لم يتم العثور على رقمك");
      setState(() => _isLoading = false);   // ← مهم جداً
      return;
    }

    final result = await ApiService.addSuggestion(
      submittedByType: "Shop",
      submittedById: ownerId,
      title: "اقتراح جديد",
      message: text,
    );

    if (result != null && result["success"] == true) {
      if (mounted) snackBar(context, "تم ارسال الاقتراح بنجاح");
      _controller.clear();
    } else {
      if (mounted) snackBar(context, "حدث خطأ اثناء الارسال");
    }

  } catch (e) {
    if (mounted) snackBar(context, "⚠️ خطأ: $e");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
Widget build(BuildContext context) {
  const Color blue = Color(0xFF1976D2);

  return Scaffold(
    backgroundColor: Colors.white,
   
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            const Text(
              'يسرنا سماع اقتراحاتك',
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

            // ✅ مربع الكتابة بارتفاع 40% وزوايا 40
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'اكتب اقتراحك هنا...',
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

    // ✅ زر الإرسال خارج السكرول ومثبت بالأسفل بنفس التصميم
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: _isLoading ? null : _submit,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
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