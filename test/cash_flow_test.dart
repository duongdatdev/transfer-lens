import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_lens/domain/cash_flow.dart';
import 'package:transfer_lens/domain/transaction.dart';

void main() {
  TransferTransaction entry(
    int amount,
    DateTime date,
    TransactionDirection direction,
  ) => TransferTransaction(
    amount: amount,
    date: date,
    direction: direction,
    category: ExpenseCategory.other,
  );

  test('daily cash flow separates directions, combines entries and isolates months', () {
    final data = CashFlowMonth.fromTransactions(DateTime(2024, 2, 15), [
      entry(
        150000,
        DateTime(2024, 2, 29, 23, 59),
        TransactionDirection.expense,
      ),
      entry(50000, DateTime(2024, 2, 29), TransactionDirection.expense),
      entry(300000, DateTime(2024, 2, 29), TransactionDirection.income),
      entry(10000, DateTime(2024, 2, 1), TransactionDirection.expense),
      entry(999999, DateTime(2024, 3, 1), TransactionDirection.expense),
      entry(999999, DateTime(2023, 2, 1), TransactionDirection.income),
    ]);
    expect(data.month, DateTime(2024, 2));
    expect(data.expenses.length, 29);
    expect(data.expenses.last, 200000);
    expect(data.income.last, 300000);
    expect(data.expenses.first, 10000);
    expect(data.expenses[1], 0);
    expect(data.totalExpense, 210000);
    expect(data.net, 90000);
    expect(() => data.income.add(0), throwsUnsupportedError);
  });

  test('empty months have all calendar days and zero net', () {
    for (final (month, days) in [
      (DateTime(2025, 2), 28),
      (DateTime(2026, 4), 30),
      (DateTime(2026, 12), 31),
    ]) {
      final data = CashFlowMonth.fromTransactions(month, []);
      expect(data.income.length, days);
      expect(data.expenses.length, days);
      expect(data.isEmpty, isTrue);
      expect(data.net, 0);
    }
  });
}
