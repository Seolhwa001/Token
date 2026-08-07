import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'refund_record.dart';

class RefundRepository {
  static const storageKey = 'token.refunds.v1';

  Future<void> append(RefundRecord refund) async {
    final refunds = await _listAll();

    if (refunds.any((item) => item.id == refund.id)) {
      throw StateError('Refund already exists: ${refund.id}');
    }

    await _write([...refunds, refund]);
  }

  Future<List<RefundRecord>> listByTransaction(String transactionId) async {
    final records = (await _listAll())
        .where((item) => item.transactionId == transactionId)
        .toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return List.unmodifiable(records);
  }

  Future<List<RefundRecord>> _listAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);

    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return List.unmodifiable(
      decoded.map(
        (item) => RefundRecord.fromJson(
          Map<String, Object?>.from(item as Map),
        ),
      ),
    );
  }

  Future<void> _write(List<RefundRecord> refunds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(refunds.map((item) => item.toJson()).toList()),
    );
  }
}
