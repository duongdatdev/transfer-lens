import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import '../domain/transfer_parser.dart';
import '../services/image_storage.dart';

class ExpenseStore extends ChangeNotifier {
  ExpenseStore(this.repository, this.preferences, {ImageStorage? images})
    : images = images ?? ImageStorage();
  final TransactionRepository repository;
  final SharedPreferences preferences;
  final ImageStorage images;
  List<TransferTransaction> _transactions = [];
  List<TransferTransaction> get transactions =>
      List.unmodifiable(_transactions);
  bool loading = false;
  String? error;
  ThemeMode get themeMode =>
      ThemeMode.values.byName(preferences.getString('theme') ?? 'system');

  Future<void> setTheme(ThemeMode mode) async {
    await preferences.setString('theme', mode.name);
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _transactions = await repository.all();
    } catch (_) {
      error = 'Không thể đọc dữ liệu. Vui lòng thử lại.';
    }
    loading = false;
    notifyListeners();
  }

  TransferTransaction? duplicateOf(TransferTransaction value) {
    for (final item in _transactions) {
      if (item.id == value.id) continue;
      if (value.reference.isNotEmpty &&
          normalizeText(item.reference) == normalizeText(value.reference)) {
        return item;
      }
      if (item.amount == value.amount &&
          item.direction == value.direction &&
          formatDate(item.date) == formatDate(value.date) &&
          normalizeText(item.sender) == normalizeText(value.sender) &&
          normalizeText(item.recipient) == normalizeText(value.recipient) &&
          normalizeText(item.description) == normalizeText(value.description)) {
        return item;
      }
    }
    return null;
  }

  Future<void> save(TransferTransaction value) async {
    final id = await repository.save(value);
    final saved = TransferTransaction.fromMap({...value.toMap(), 'id': id});
    _transactions = [..._transactions.where((t) => t.id != id), saved]
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate == 0 ? b.id!.compareTo(a.id!) : byDate;
      });
    notifyListeners();
  }

  Future<void> delete(TransferTransaction value) async {
    await repository.delete(value.id!);
    _transactions = _transactions.where((t) => t.id != value.id).toList();
    notifyListeners();
    // Database deletion succeeds first; a file cleanup failure must not resurrect a record.
    try {
      await images.remove(value.imagePath);
      await images.remove(value.thumbnailPath);
    } catch (_) {
      /* Orphaned cache is harmless and remains private to the app. */
    }
  }
}
