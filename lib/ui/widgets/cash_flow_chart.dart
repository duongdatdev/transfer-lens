import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/cash_flow.dart';
import '../../domain/transaction.dart';

class CashFlowChart extends StatefulWidget {
  const CashFlowChart({super.key, required this.data});
  final CashFlowMonth data;

  @override
  State<CashFlowChart> createState() => _CashFlowChartState();
}

class _CashFlowChartState extends State<CashFlowChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<double> _fromIncome;
  late List<double> _fromExpenses;
  late List<double> _toIncome;
  late List<double> _toExpenses;
  int _selected = 0;
  bool _reveal = true;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _setTargets();
    _fromIncome = _toIncome;
    _fromExpenses = _toExpenses;
    _selected = _initialDay();
    _controller.forward();
  }

  int _initialDay() {
    final now = DateTime.now();
    if (now.year == widget.data.month.year &&
        now.month == widget.data.month.month) {
      return now.day - 1;
    }
    for (var i = widget.data.income.length - 1; i >= 0; i--) {
      if (widget.data.income[i] > 0 || widget.data.expenses[i] > 0) return i;
    }
    return 0;
  }

  void _setTargets() {
    _toIncome = widget.data.income.map((v) => v.toDouble()).toList();
    _toExpenses = widget.data.expenses.map((v) => v.toDouble()).toList();
  }

  double get _progress => Curves.easeOutCubic.transform(_controller.value);

  List<double> _interpolate(List<double> from, List<double> to) =>
      List.generate(to.length, (i) => from[i] + (to[i] - from[i]) * _progress);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant CashFlowChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedMonth = oldWidget.data.month != widget.data.month;
    if (!changedMonth &&
        listEquals(oldWidget.data.income, widget.data.income) &&
        listEquals(oldWidget.data.expenses, widget.data.expenses)) {
      return;
    }
    // Continue interrupted updates from the values currently displayed.
    _fromIncome = _interpolate(_fromIncome, _toIncome);
    _fromExpenses = _interpolate(_fromExpenses, _toExpenses);
    _setTargets();
    _reveal = changedMonth;
    if (changedMonth) {
      _fromIncome = _toIncome;
      _fromExpenses = _toExpenses;
      _selected = _initialDay();
    }
    _controller.duration = Duration(milliseconds: changedMonth ? 900 : 500);
    if (_reducedMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int day) =>
      setState(() => _selected = day.clamp(0, widget.data.income.length - 1));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = widget.data;
    final date = DateTime(data.month.year, data.month.month, _selected + 1);
    final highest = [...data.income, ...data.expenses].fold(0, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _legend('Thu · nét đứt', scheme.primary, true),
            _legend('Chi · nét liền', scheme.error, false),
          ],
        ),
        const SizedBox(height: 12),
        Text('Theo từng ngày · Mốc cao nhất: ${formatMoney(highest)}'),
        const SizedBox(height: 12),
        Semantics(
          label:
              'Biểu đồ biến động thu chi tháng ${data.month.month}/${data.month.year}. '
              'Tổng thu ${formatMoney(data.totalIncome)}, tổng chi ${formatMoney(data.totalExpense)}. '
              'Dùng nút ngày trước và ngày sau để xem từng ngày.',
          child: SizedBox(
            height: 190,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                key: const ValueKey('cash-flow-plot'),
                onTapUp: (details) => _select(
                  ((details.localPosition.dx - 8) /
                          (constraints.maxWidth - 16) *
                          (data.income.length - 1))
                      .round(),
                ),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      size: Size(constraints.maxWidth, 190),
                      painter: CashFlowPainter(
                        income: _interpolate(_fromIncome, _toIncome),
                        expenses: _interpolate(_fromExpenses, _toExpenses),
                        reveal: _reveal ? _controller.value : 1,
                        selected: _selected,
                        incomeColor: scheme.primary,
                        expenseColor: scheme.error,
                        gridColor: scheme.outlineVariant,
                        surfaceColor: scheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('01'),
            Text('${(data.income.length + 1) ~/ 2}'.padLeft(2, '0')),
            Text('${data.income.length}'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Ngày trước',
                    onPressed: _selected > 0
                        ? () => _select(_selected - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      formatDate(date),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ngày sau',
                    onPressed: _selected < data.income.length - 1
                        ? () => _select(_selected + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Semantics(
                liveRegion: true,
                label: 'Ngày ${formatDate(date)}',
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text('Thu: ${formatMoney(data.income[_selected])}'),
                    Text('Chi: ${formatMoney(data.expenses[_selected])}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Chênh lệch tháng (thu − chi): ${formatMoney(data.net)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (data.isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Tháng này chưa có giao dịch. Lưu giao dịch để xem biến động.',
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('replay-cash-flow'),
          onPressed: _reducedMotion || data.isEmpty
              ? null
              : () {
                  _reveal = true;
                  _fromIncome = _toIncome;
                  _fromExpenses = _toExpenses;
                  _controller.duration = const Duration(milliseconds: 900);
                  _controller.forward(from: 0);
                },
          icon: const Icon(Icons.replay),
          label: Text(
            _reducedMotion ? 'Đã bật giảm chuyển động' : 'Phát lại biểu đồ',
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, Color color, bool dashed) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 24,
        child: Text(
          dashed ? '┄' : '━',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
      Flexible(child: Text(label)),
    ],
  );
}

class CashFlowPainter extends CustomPainter {
  CashFlowPainter({
    required this.income,
    required this.expenses,
    required this.reveal,
    required this.selected,
    required this.incomeColor,
    required this.expenseColor,
    required this.gridColor,
    required this.surfaceColor,
  });

  final List<double> income;
  final List<double> expenses;
  final double reveal;
  final int selected;
  final Color incomeColor;
  final Color expenseColor;
  final Color gridColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(8, 8, size.width - 8, size.height - 8);
    final maximum = math.max(1.0, [...income, ...expenses].fold(0.0, math.max));
    Offset point(int i, double value) => Offset(
      plot.left + plot.width * i / (income.length - 1),
      plot.bottom - value / maximum * plot.height,
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }
    final selectionX = point(selected, 0).dx;
    canvas.drawLine(
      Offset(selectionX, plot.top),
      Offset(selectionX, plot.bottom),
      gridPaint..strokeWidth = 2,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    void drawSeries(List<double> values, Color color, bool dashed) {
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final p = point(i, values[i]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      final metric = path.computeMetrics().first;
      final length = metric.length * reveal;
      if (length <= 0) return;
      final visiblePath = metric.extractPath(0, length);
      final end = metric.getTangentForOffset(length)!.position;
      if (!dashed) {
        final fill = Path.from(visiblePath)
          ..lineTo(end.dx, plot.bottom)
          ..lineTo(plot.left, plot.bottom)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: .18),
                color.withValues(alpha: .02),
              ],
            ).createShader(plot),
        );
      }
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      if (dashed) {
        for (final metric in visiblePath.computeMetrics()) {
          for (var offset = 0.0; offset < metric.length; offset += 12) {
            canvas.drawPath(
              metric.extractPath(offset, math.min(offset + 6, metric.length)),
              paint,
            );
          }
        }
      } else {
        canvas.drawPath(visiblePath, paint);
      }
      for (var i = 0; i < values.length; i++) {
        if (values[i] <= 0 && i != selected) continue;
        final p = point(i, values[i]);
        if (p.dx > end.dx + .1) continue;
        canvas.drawCircle(
          p,
          i == selected ? 5 : 3,
          Paint()..color = surfaceColor,
        );
        canvas.drawCircle(p, i == selected ? 5 : 3, paint..strokeWidth = 2);
      }
    }

    drawSeries(expenses, expenseColor, false);
    drawSeries(income, incomeColor, true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CashFlowPainter oldDelegate) =>
      !listEquals(oldDelegate.income, income) ||
      !listEquals(oldDelegate.expenses, expenses) ||
      oldDelegate.reveal != reveal ||
      oldDelegate.selected != selected ||
      oldDelegate.incomeColor != incomeColor ||
      oldDelegate.expenseColor != expenseColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.surfaceColor != surfaceColor;
}
