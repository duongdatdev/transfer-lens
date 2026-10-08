import 'transaction.dart';

class CashFlowMonth {
  CashFlowMonth._(this.month, this.income, this.expenses);

  factory CashFlowMonth.fromTransactions(
    DateTime month,
    Iterable<TransferTransaction> transactions,
  ) {
    final start = DateTime(month.year, month.month);
    final days = DateTime(start.year, start.month + 1, 0).day;
    final income = List<int>.filled(days, 0);
    final expenses = List<int>.filled(days, 0);
    for (final transaction in transactions) {
      if (transaction.date.year != start.year ||
          transaction.date.month != start.month) {
        continue;
      }
      final values = transaction.direction == TransactionDirection.income
          ? income
          : expenses;
      values[transaction.date.day - 1] += transaction.amount;
    }
    return CashFlowMonth._(
      start,
      List.unmodifiable(income),
      List.unmodifiable(expenses),
    );
  }

  final DateTime month;
  final List<int> income;
  final List<int> expenses;
  int get totalIncome => income.fold(0, (sum, amount) => sum + amount);
  int get totalExpense => expenses.fold(0, (sum, amount) => sum + amount);
  int get net => totalIncome - totalExpense;
  bool get isEmpty => totalIncome == 0 && totalExpense == 0;
}
