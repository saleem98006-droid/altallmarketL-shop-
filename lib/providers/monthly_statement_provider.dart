import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class MonthlyStatementRequest {
  final int shopId;
  final int month;

  const MonthlyStatementRequest({
    required this.shopId,
    required this.month,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyStatementRequest &&
        other.shopId == shopId &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(shopId, month);
}

class MonthlyStatementMovement {
  final int paymentId;
  final double credit;
  final double debit;
  final double balance;
  final String notes;
  final DateTime? date;

  const MonthlyStatementMovement({
    required this.paymentId,
    required this.credit,
    required this.debit,
    required this.balance,
    required this.notes,
    required this.date,
  });

  factory MonthlyStatementMovement.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['date']?.toString() ?? '';
    if (rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return MonthlyStatementMovement(
      paymentId: _toInt(json['paymentId']),
      credit: _toDouble(json['credit']),
      debit: _toDouble(json['debit']),
      balance: _toDouble(json['balance']),
      notes: (json['notes'] ?? '').toString(),
      date: parsedDate,
    );
  }

  bool get isCredit => credit > 0;
  double get amount => isCredit ? credit : debit;
}

class MonthlyStatementData {
  final int shopId;
  final int year;
  final int month;
  final double totalWithdrawals;
  final double commissionPercent;
  final double commissionValue;
  final double netBalance;
  final List<MonthlyStatementMovement> accountMovements;

  const MonthlyStatementData({
    required this.shopId,
    required this.year,
    required this.month,
    required this.totalWithdrawals,
    required this.commissionPercent,
    required this.commissionValue,
    required this.netBalance,
    required this.accountMovements,
  });

  factory MonthlyStatementData.fromJson(Map<String, dynamic> json) {
    final movementsRaw = json['accountMovements'];
    final movements = <MonthlyStatementMovement>[];

    if (movementsRaw is List) {
      for (final item in movementsRaw) {
        if (item is Map) {
          movements.add(
            MonthlyStatementMovement.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return MonthlyStatementData(
      shopId: _toInt(json['shopId']),
      year: _toInt(json['year']),
      month: _toInt(json['month']),
      totalWithdrawals: _toDouble(json['totalWithdrawals']),
      commissionPercent: _toDouble(json['commissionPercent']),
      commissionValue: _toDouble(json['commissionValue']),
      netBalance: _toDouble(json['netBalance']),
      accountMovements: movements,
    );
  }
}

final currentShopIdProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('shopId') ?? 0;
});

final monthlyStatementProvider =
    FutureProvider.family<MonthlyStatementData, MonthlyStatementRequest>(
  (ref, request) async {
    final response = await ApiService.getShopMonthlyStatement(
      shopId: request.shopId,
      month: request.month,
    );

    if (response == null || response['success'] != true) {
      throw Exception('تعذر تحميل كشف المستحقات');
    }

    return MonthlyStatementData.fromJson(response);
  },
);

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
