import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../widgets/loading_dots_widget.dart';
import '../snackBar/snackbar.dart';

class ExchangeRateScreen extends StatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  State<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  final TextEditingController _rateController = TextEditingController();

  int? _shopId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRate();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentRate() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;

    if (shopId == 0) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      snackBar(context, 'لم يتم العثور على رقم المحل');
      return;
    }

    final result = await ApiService.getOrUpdateExchangeRate(shopId: shopId);

    if (!mounted) return;

    if (result != null) {
      final rate = result['exchangeRate'];
      _rateController.text =
          rate == null ? '' : double.tryParse(rate.toString())?.toString() ?? '';
      await prefs.setDouble(
        'exchangeRate',
        double.tryParse(_rateController.text) ?? 0,
      );
    }

    setState(() {
      _shopId = shopId;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (_isSaving || _shopId == null || _shopId == 0) return;

    final rate = double.tryParse(_rateController.text.trim());
    if (rate == null || rate <= 0) {
      snackBar(context, 'الرجاء إدخال سعر صرف صحيح');
      return;
    }

    setState(() => _isSaving = true);

    final result = await ApiService.getOrUpdateExchangeRate(
      shopId: _shopId!,
      newExchangeRate: rate,
    );

    if (!mounted) return;

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('exchangeRate', rate);
      snackBar(context, result['message']?.toString() ?? 'تم تحديث سعر الصرف');
    } else {
      snackBar(context, 'فشل تحديث سعر الصرف');
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 90),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 45),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                const Spacer(),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

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
                'سعر الصرف',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'يمكنك عرض وتعديل سعر الصرف الحالي',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'سعر الصرف (ل.س لكل دولار)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color(0xFF5A9BD5), width: 1.5),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color(0xFF5A9BD5), width: 2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _isSaving ? null : _submit,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFF5A9BD5), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isSaving
                ? const LoadingDotsWidget()
                : const Text(
                    'تأكيد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: Color(0xFF5A9BD5),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
