import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/transaction.dart';
import '../app_theme.dart';

class CategoryChart extends StatefulWidget {
  const CategoryChart({super.key, required this.totals});
  final Map<ExpenseCategory, int> totals;
  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  ExpenseCategory? selected;
  @override
  Widget build(BuildContext context) {
    final entries = widget.totals.entries.where((e) => e.value > 0).toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);
    final active = entries.where((e) => e.key == selected).firstOrNull;
    return Column(
      children: [
        Semantics(
          label:
              'Phân bổ chi tiêu theo danh mục. Tổng ${formatMoney(total)}. Chọn danh mục bên dưới để xem chi tiết.',
          child: SizedBox(
            height: 220,
            child: Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: GestureDetector(
                  onTapUp: (details) {
                    final offset =
                        details.localPosition - const Offset(110, 110);
                    if (offset.distance < 72 ||
                        offset.distance > 106 ||
                        total == 0) {
                      return;
                    }
                    final angle =
                        (math.atan2(offset.dy, offset.dx) +
                            math.pi / 2 +
                            math.pi * 2) %
                        (math.pi * 2);
                    var end = 0.0;
                    for (final entry in entries) {
                      end += entry.value / total * math.pi * 2;
                      if (angle < end) {
                        setState(() => selected = entry.key);
                        break;
                      }
                    }
                  },
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(widget.totals.toString()),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(
                      milliseconds: MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : 750,
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, _) => CustomPaint(
                      painter: DonutPainter(
                        entries,
                        progress,
                        selected,
                        Theme.of(context).colorScheme.outlineVariant,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(56),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 108,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    active?.key.label ?? 'Tổng chi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    child: Text(
                                      formatMoney(active?.value ?? total),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                  if (active != null)
                                    Text(
                                      '${(active.value / total * 100).round()}%',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (total == 0)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Lưu khoản chi đầu tiên để xem phân bổ.'),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: entries
              .map(
                (entry) => FilterChip(
                  showCheckmark: true,
                  avatar: Icon(
                    categoryIcon(entry.key),
                    size: 18,
                    color: categoryColor(entry.key),
                  ),
                  label: Text(
                    '${entry.key.label} ${(entry.value / total * 100).round()}%',
                  ),
                  selected: selected == entry.key,
                  onSelected: (_) => setState(
                    () => selected = selected == entry.key ? null : entry.key,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.entries, this.progress, this.selected, this.emptyColor);
  final List<MapEntry<ExpenseCategory, int>> entries;
  final double progress;
  final ExpenseCategory? selected;
  final Color emptyColor;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(
      center: center,
      radius: size.shortestSide / 2 - 18,
    );
    final total = entries.fold(0, (sum, e) => sum + e.value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;
    canvas.drawCircle(
      center,
      rect.width / 2,
      paint..color = emptyColor.withValues(alpha: .5),
    );
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final entry in entries) {
      final sweep = entry.value / total * math.pi * 2;
      paint.color = categoryColor(
        entry.key,
      ).withValues(alpha: selected == null || selected == entry.key ? 1 : .3);
      paint.strokeWidth = selected == entry.key ? 30 : 24;
      canvas.drawArc(
        rect,
        start + .025,
        math.max(0, sweep * progress - .05),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.entries != entries ||
      oldDelegate.selected != selected ||
      oldDelegate.emptyColor != emptyColor;
}

class WeeklyChart extends StatefulWidget {
  const WeeklyChart({super.key, required this.amounts, required this.monday});
  final List<int> amounts;
  final DateTime monday;
  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  int? selected;
  static const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = widget.amounts.fold(0, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected == null
              ? 'Cao nhất: ${formatMoney(maxValue)}'
              : '${formatDate(widget.monday.add(Duration(days: selected!)))} · ${formatMoney(widget.amounts[selected!])}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapUp: (details) => setState(
                () => selected =
                    (details.localPosition.dx / (constraints.maxWidth / 7))
                        .floor()
                        .clamp(0, 6),
              ),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(widget.amounts.join(',')),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(
                  milliseconds: MediaQuery.disableAnimationsOf(context)
                      ? 0
                      : 650,
                ),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => CustomPaint(
                  size: Size(constraints.maxWidth, 160),
                  painter: BarPainter(
                    widget.amounts,
                    progress,
                    selected,
                    scheme.primary,
                    scheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: List.generate(
            7,
            (i) => Expanded(
              child: Semantics(
                label: '${days[i]}: ${formatMoney(widget.amounts[i])}',
                selected: selected == i,
                child: TextButton(
                  onPressed: () => setState(() => selected = i),
                  child: Text(
                    days[i],
                    style: TextStyle(
                      fontWeight: selected == i
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (maxValue == 0) const Text('Tuần này chưa có khoản chi.'),
      ],
    );
  }
}

class BarPainter extends CustomPainter {
  BarPainter(
    this.values,
    this.progress,
    this.selected,
    this.color,
    this.gridColor,
  );
  final List<int> values;
  final double progress;
  final int? selected;
  final Color color;
  final Color gridColor;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: .6)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final maximum = math.max(1, values.fold(0, math.max));
    final cell = size.width / 7;
    for (var i = 0; i < 7; i++) {
      final height = values[i] / maximum * (size.height - 8) * progress;
      if (height == 0) continue;
      paint.color = color.withValues(
        alpha: selected == null || selected == i ? 1 : .3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * cell + cell * .23,
            size.height - height,
            cell * .54,
            height,
          ),
          const Radius.circular(8),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.progress != progress ||
      oldDelegate.selected != selected ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}
