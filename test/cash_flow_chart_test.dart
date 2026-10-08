import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_lens/domain/cash_flow.dart';
import 'package:transfer_lens/domain/transaction.dart';
import 'package:transfer_lens/ui/app_theme.dart';
import 'package:transfer_lens/ui/widgets/cash_flow_chart.dart';

void main() {
  CashFlowMonth data(int expense, {int income = 300000, int month = 2}) =>
      CashFlowMonth.fromTransactions(DateTime(2024, month), [
        TransferTransaction(
          amount: expense,
          date: DateTime(2024, month, 1),
          direction: TransactionDirection.expense,
          category: ExpenseCategory.food,
        ),
        TransferTransaction(
          amount: income,
          date: DateTime(2024, month, 2),
          direction: TransactionDirection.income,
          category: ExpenseCategory.other,
        ),
      ]);

  Widget app(
    CashFlowMonth values, {
    bool reduced = false,
    bool dark = false,
    double textScale = 1,
  }) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: CashFlowChart(data: values),
          ),
        ),
      ),
    ),
  );

  CashFlowPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter)
      .whereType<CashFlowPainter>()
      .single;

  testWidgets('reveal, tap inspection, replay and interrupted live updates', (
    tester,
  ) async {
    await tester.pumpWidget(app(data(100000)));
    await tester.pump(const Duration(milliseconds: 150));
    expect(painter(tester).reveal, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(painter(tester).reveal, 1);
    await tester.tap(
      find.byKey(const ValueKey('cash-flow-plot')),
      warnIfMissed: true,
    );
    await tester.pump();
    expect(painter(tester).selected, 14);
    await tester.tap(find.byTooltip('Ngày trước'));
    await tester.pump();
    expect(find.text('14/02/2024'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('replay-cash-flow')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter(tester).reveal, lessThan(1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(data(200000)));
    await tester.pump(const Duration(milliseconds: 150));
    final intermediate = painter(tester).expenses.first;
    expect(intermediate, inExclusiveRange(100000, 200000));
    await tester.pumpWidget(app(data(50000)));
    expect(painter(tester).expenses.first, closeTo(intermediate, 1));
    await tester.pumpAndSettle();
    expect(painter(tester).expenses.first, 50000);
    expect(
      find.text('Chênh lệch tháng (thu − chi): 250.000 ₫'),
      findsOneWidget,
    );
    await tester.pumpWidget(app(data(0, month: 3), dark: true));
    await tester.pumpAndSettle();
    expect(painter(tester).expenses.length, 31);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion and empty data remain inspectable', (
    tester,
  ) async {
    await tester.pumpWidget(app(data(100000), reduced: true));
    await tester.pumpAndSettle();
    expect(painter(tester).reveal, 1);
    final replay = tester.widget<TextButton>(
      find.byKey(const ValueKey('replay-cash-flow')),
    );
    expect(replay.onPressed, isNull);
    await tester.tap(find.byTooltip('Ngày trước'));
    await tester.pumpAndSettle();
    expect(find.text('Thu: 0 ₫'), findsOneWidget);
    expect(find.text('Chi: 100.000 ₫'), findsOneWidget);
    await tester.pumpWidget(app(data(0, income: 0), reduced: true, dark: true));
    await tester.pumpAndSettle();
    expect(painter(tester).expenses.first, 0);
    expect(find.textContaining('Tháng này chưa có giao dịch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('cash flow fits $size with 200% text, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          app(data(1000000000, income: 2000000000), dark: dark, textScale: 2),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
