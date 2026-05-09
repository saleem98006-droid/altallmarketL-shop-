import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State class for account information
class AccountState {
  final bool isActive;
  final bool isAccepted;
  final String deliveryType;

  AccountState({
    required this.isActive,
    required this.isAccepted,
    required this.deliveryType,
  });

  AccountState copyWith({
    bool? isActive,
    bool? isAccepted,
    String? deliveryType,
  }) {
    return AccountState(
      isActive: isActive ?? this.isActive,
      isAccepted: isAccepted ?? this.isAccepted,
      deliveryType: deliveryType ?? this.deliveryType,
    );
  }
}

// Notifier for managing account state
class AccountNotifier extends StateNotifier<AccountState> {
  AccountNotifier()
      : super(
          AccountState(
            isActive: true,
            isAccepted: false,
            deliveryType: '',
          ),
        );

  // تحميل البيانات من SharedPreferences عند بدء التطبيق
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final isActive = prefs.getBool('isActive') ?? true;
    final isAccepted = prefs.getBool('isAccepted') ?? false;
    final deliveryType = prefs.getString('deliveryType') ?? '';

    state = state.copyWith(
      isActive: isActive,
      isAccepted: isAccepted,
      deliveryType: deliveryType,
    );
  }

  // تحديث isActive
  Future<void> setActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isActive', value);
    state = state.copyWith(isActive: value);
  }

  // تحديث isAccepted
  Future<void> setAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAccepted', value);
    state = state.copyWith(isAccepted: value);
  }

  // تحديث نوع الحساب
  Future<void> setDeliveryType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deliveryType', value);
    state = state.copyWith(deliveryType: value);
  }

  // إعادة تعيين جميع البيانات
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('isActive');
    await prefs.remove('isAccepted');
    await prefs.remove('deliveryType');

    state = AccountState(
      isActive: true,
      isAccepted: false,
      deliveryType: '',
    );
  }
}

// Riverpod Provider
final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier();
});