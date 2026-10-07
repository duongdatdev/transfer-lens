import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transfer_lens/data/transaction_repository.dart';
import 'package:transfer_lens/domain/transaction.dart';
import 'package:transfer_lens/domain/transfer_parser.dart';
import 'package:transfer_lens/main.dart';
import 'package:transfer_lens/state/expense_store.dart';
import 'package:transfer_lens/ui/app_theme.dart';
import 'package:transfer_lens/ui/review_screen.dart';
import 'package:transfer_lens/ui/widgets/spending_charts.dart';

class MemoryRepository implements TransactionRepository {
  final values = <TransferTransaction>[];
  @override
  Future<List<TransferTransaction>> all() async => values;
  @override
  Future<int> save(TransferTransaction value) async {
    values.add(value);
    return values.length;
  }

  @override
  Future<void> delete(int id) async {
    values.removeWhere((value) => value.id == id);
  }

  @override
  Future<void> close() async {}
}

void main() {
  Future<ExpenseStore> createStore() async {
    SharedPreferences.setMockInitialValues({});
    return ExpenseStore(
      MemoryRepository(),
      await SharedPreferences.getInstance(),
    );
  }

  for (final size in [
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('dashboard fits $size at text scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = await createStore();
        final now = DateTime.now();
        await store.save(
          TransferTransaction(
            amount: 150000,
            date: now,
            direction: TransactionDirection.expense,
            category: ExpenseCategory.food,
            recipient: 'TRAN THI BINH',
          ),
        );
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: store,
            child: const TransferLensApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).first, const Offset(0, -480));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await store.setTheme(ThemeMode.dark);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('review requires amount, date, category and confirmation', (
    tester,
  ) async {
    final store = await createStore();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ReviewScreen(parsed: ParsedTransfer()),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('save')),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('save')));
    await tester.pumpAndSettle();
    expect(find.text('Chọn danh mục trước khi lưu.'), findsOneWidget);
    expect(store.transactions, isEmpty);
  });

  testWidgets('charts expose selectable values with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const CategoryChart(
                    totals: {
                      ExpenseCategory.food: 100000,
                      ExpenseCategory.study: 300000,
                    },
                  ),
                  WeeklyChart(
                    amounts: const [0, 0, 150000, 0, 0, 0, 0],
                    monday: DateTime(2026, 10, 5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống 25%'));
    await tester.pumpAndSettle();
    expect(find.text('100.000 ₫'), findsOneWidget);
    await tester.tap(find.text('T4'));
    await tester.pumpAndSettle();
    expect(find.text('07/10/2026 · 150.000 ₫'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
