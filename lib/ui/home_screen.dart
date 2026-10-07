import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/transaction.dart';
import '../state/expense_store.dart';
import 'app_theme.dart';
import 'import_screen.dart';
import 'review_screen.dart';
import 'widgets/spending_charts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int page = 0;
  String query = '';
  ExpenseCategory? filter;
  TransactionDirection? direction;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime week = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ExpenseStore>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.document_scanner_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'TransferLens',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.tune_outlined),
            onPressed: _settings,
          ),
        ],
      ),
      body: ContentWidth(
        child: store.loading
            ? const Center(child: CircularProgressIndicator())
            : store.error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(store.error!),
                    FilledButton(
                      onPressed: store.load,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: store.load,
                child: page == 0 ? _dashboard(store) : _history(store),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ImportScreen())),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Nhập ảnh'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (value) => setState(() => page = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Giao dịch',
          ),
        ],
      ),
    );
  }

  Widget _dashboard(ExpenseStore store) {
    final monthly = store.transactions
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .toList();
    final expenses = monthly
        .where((t) => t.direction == TransactionDirection.expense)
        .toList();
    final total = expenses.fold(0, (sum, t) => sum + t.amount);
    final income = monthly
        .where((t) => t.direction == TransactionDirection.income)
        .fold(0, (sum, t) => sum + t.amount);
    final totals = {
      for (final c in ExpenseCategory.values)
        c: expenses
            .where((t) => t.category == c)
            .fold(0, (sum, t) => sum + t.amount),
    };
    final amounts = List<int>.filled(7, 0);
    for (final t in store.transactions.where(
      (t) => t.direction == TransactionDirection.expense,
    )) {
      final day = DateTime(
        t.date.year,
        t.date.month,
        t.date.day,
      ).difference(week).inDays;
      if (day >= 0 && day < 7) amounts[day] += t.amount;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text(
          'Chi tiêu, rõ ràng hơn.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Một ảnh chuyển khoản. Một giao dịch đã được kiểm tra.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _period(
          'Tháng ${month.month}/${month.year}',
          () => setState(() => month = DateTime(month.year, month.month - 1)),
          () => setState(() => month = DateTime(month.year, month.month + 1)),
          'tháng',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.arrow_outward,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TỔNG CHI THÁNG NÀY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(total),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  Text(
                    '${expenses.length} khoản chi',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Thu: ${formatMoney(income)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final category = _chartCard(
              'Tiền đi đâu?',
              'Phân bổ khoản chi trong tháng',
              CategoryChart(totals: totals),
            );
            final weekly = _chartCard(
              'Nhịp chi tiêu',
              'Chạm cột hoặc ngày để xem số tiền',
              Column(
                children: [
                  _period(
                    '${formatDate(week)} - ${formatDate(week.add(const Duration(days: 6)))}',
                    () => setState(
                      () => week = week.subtract(const Duration(days: 7)),
                    ),
                    () => setState(
                      () => week = week.add(const Duration(days: 7)),
                    ),
                    'tuần',
                  ),
                  const SizedBox(height: 16),
                  WeeklyChart(amounts: amounts, monday: week),
                ],
              ),
            );
            return constraints.maxWidth > 700
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: category),
                      const SizedBox(width: 16),
                      Expanded(child: weekly),
                    ],
                  )
                : Column(
                    children: [category, const SizedBox(height: 20), weekly],
                  );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Giao dịch gần đây',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => page = 1),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (store.transactions.isEmpty)
          _emptyState()
        else
          ...store.transactions.take(4).map(_transactionTile),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ảnh và giao dịch được lưu trên thiết bị của bạn.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _period(
    String title,
    VoidCallback previous,
    VoidCallback next,
    String unit,
  ) => Row(
    children: [
      IconButton(
        tooltip: '$unit trước',
        onPressed: previous,
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      IconButton(
        tooltip: '$unit sau',
        onPressed: next,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );

  Widget _chartCard(String title, String subtitle, Widget child) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );

  Widget _history(ExpenseStore store) {
    final list = store.transactions
        .where(
          (t) =>
              (filter == null || t.category == filter) &&
              (direction == null || t.direction == direction) &&
              '${t.sender} ${t.recipient} ${t.description} ${t.reference}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sổ giao dịch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    labelText: 'Tìm người hoặc nội dung',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: direction == null,
                      onSelected: (_) => setState(() => direction = null),
                    ),
                    ChoiceChip(
                      label: const Text('Khoản chi'),
                      selected: direction == TransactionDirection.expense,
                      onSelected: (_) => setState(
                        () => direction = TransactionDirection.expense,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Khoản thu'),
                      selected: direction == TransactionDirection.income,
                      onSelected: (_) => setState(
                        () => direction = TransactionDirection.income,
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: filter,
                  decoration: const InputDecoration(labelText: 'Lọc danh mục'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Mọi danh mục'),
                    ),
                    ...ExpenseCategory.values.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    ),
                  ],
                  onChanged: (value) => setState(() => filter = value),
                ),
                const SizedBox(height: 16),
                Text(
                  '${list.length} giao dịch',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _emptyState(isFiltered: store.transactions.isNotEmpty),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: list.length,
              itemBuilder: (_, index) => _transactionTile(list[index]),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _emptyState({bool isFiltered = false}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.photo_library_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered ? 'Không tìm thấy giao dịch' : 'Bắt đầu từ một ảnh',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered ? 'Thử từ khóa hoặc danh mục khác.' : 'Nhập ảnh chuyển khoản thành công. Kiểm tra số tiền và danh mục trước khi lưu.',
            textAlign: TextAlign.center,
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ImportScreen()),
              ),
              child: const Text('Nhập giao dịch đầu tiên'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _transactionTile(TransferTransaction value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: value.thumbnailPath != null
              ? Image.file(
                  File(value.thumbnailPath!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _categoryBadge(value.category),
                )
              : _categoryBadge(value.category),
        ),
        title: Text(
          value.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${value.category.label} · ${formatDate(value.date)}',
          maxLines: 2,
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 132),
          child: Text(
            '${value.direction == TransactionDirection.expense ? '-' : '+'}${formatMoney(value.amount)}',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: value.direction == TransactionDirection.income
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => ReviewScreen(existing: value),
          ),
        ),
      ),
    ),
  );

  Widget _categoryBadge(ExpenseCategory category) => Container(
    width: 48,
    height: 48,
    color: categoryColor(category).withValues(alpha: .15),
    child: Icon(categoryIcon(category), color: categoryColor(category)),
  );

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Consumer<ExpenseStore>(
            builder: (context, store, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cài đặt',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                RadioGroup<ThemeMode>(
                  groupValue: store.themeMode,
                  onChanged: (value) {
                    if (value != null) store.setTheme(value);
                  },
                  child: Column(
                    children: ThemeMode.values
                        .map(
                          (mode) => RadioListTile<ThemeMode>(
                            title: Text(switch (mode) {
                              ThemeMode.system => 'Theo hệ thống',
                              ThemeMode.light => 'Giao diện sáng',
                              ThemeMode.dark => 'Giao diện tối',
                            }),
                            value: mode,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Riêng tư trên thiết bị'),
                  subtitle: Text(
                    'OCR ngoại tuyến. Không đăng nhập, không tải ảnh lên máy chủ. Xóa giao dịch sẽ xóa cả ảnh đã lưu.',
                  ),
                ),
                const Text('TransferLens 1.0.0 · Mini-Project #3'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
