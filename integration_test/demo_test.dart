import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:transfer_lens/data/transaction_repository.dart';
import 'package:transfer_lens/domain/transaction.dart';
import 'package:transfer_lens/main.dart';
import 'package:transfer_lens/state/expense_store.dart';
import 'package:transfer_lens/ui/home_screen.dart';
import 'package:transfer_lens/ui/widgets/spending_charts.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('record the real OCR workflow with fictional confirmations', (
    tester,
  ) async {
    final dbPath = p.join(await getDatabasesPath(), 'recording_demo.db');
    await deleteDatabase(dbPath);
    final repository = await SqliteTransactionRepository.open(path: dbPath);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', 'light');
    final store = ExpenseStore(repository, prefs);
    final screenshotDir = Directory(
      p.join(
        (await getApplicationDocumentsDirectory()).path,
        'demo_screenshots',
      ),
    );
    await screenshotDir.create(recursive: true);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const TransferLensApp(),
      ),
    );
    await tester.pumpAndSettle();

    const fast = bool.fromEnvironment('FAST_DEMO');
    var converted = false;
    Future<void> hold(int seconds) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(seconds: fast ? 1 : seconds)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      if (!converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
      }
      await tester.pumpAndSettle();
      await File(p.join(screenshotDir.path, '$name.png'))
          .writeAsBytes(await binding.takeScreenshot(name));
    }

    Future<void> reveal(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapText(String text) async {
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    Future<void> importSample(String name) async {
      await tapText('Nhập ảnh');
      await reveal(find.text(name));
      await tapText(name);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    Future<void> save() async {
      await reveal(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await reveal(find.byKey(const ValueKey('save')));
      await tester.tap(find.byKey(const ValueKey('save')));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    debugPrint('DEMO_RECORDING_START');
    debugPrint(
      'DEMO_STEP: TransferLens: ghi chi tiêu từ ảnh chuyển khoản thành công.',
    );
    await hold(8);
    await capture('01_dashboard_empty');
    await tapText('Nhập ảnh');
    debugPrint(
      'DEMO_STEP: Chọn ảnh từ thư viện, chụp ảnh hoặc thử dữ liệu giả.',
    );
    await capture('02_import');
    await hold(8);
    await reveal(find.text('Bữa trưa'));
    await tapText('Bữa trưa');
    debugPrint(
      'DEMO_STEP: ML Kit chạy OCR thật trên thiết bị. Kiểm tra số tiền và ngày.',
    );
    await hold(8);
    await capture('03_ocr_review');
    await reveal(find.byKey(const ValueKey('recipient')));
    debugPrint(
      'DEMO_STEP: Tách người gửi, người nhận và nội dung chuyển khoản.',
    );
    await capture('04_parties');
    await hold(10);
    await reveal(find.byType(DropdownButtonFormField<ExpenseCategory>));
    debugPrint('DEMO_STEP: Nội dung "an trua" gợi ý danh mục Ăn uống.');
    await capture('05_category_suggestion');
    await hold(8);
    await reveal(find.text('Văn bản OCR gốc'));
    await tapText('Văn bản OCR gốc');
    await hold(6);
    await tapText('Văn bản OCR gốc');
    await save();
    debugPrint(
      'DEMO_STEP: Xác nhận trước khi lưu. SQLite giữ dữ liệu và ảnh cục bộ.',
    );
    expect(store.transactions.single.amount, 150000);
    await hold(6);

    await importSample('Học phí');
    debugPrint('DEMO_STEP: Ảnh học phí được gợi ý vào danh mục Học tập.');
    await hold(5);
    await save();
    await importSample('Chuyển tiền');
    debugPrint(
      'DEMO_STEP: Nội dung chưa rõ: người dùng phải tự chọn danh mục.',
    );
    await reveal(find.byType(DropdownButtonFormField<ExpenseCategory>));
    await capture('06_manual_category');
    await hold(8);
    await tester.tap(find.byType(DropdownButtonFormField<ExpenseCategory>));
    await tester.pumpAndSettle();
    await tapText('Di chuyển');
    await hold(4);
    await save();
    expect(store.transactions.length, 3);
    await reveal(find.byType(CategoryChart));
    debugPrint(
      'DEMO_STEP: Biểu đồ donut vẽ bằng CustomPainter. Chạm danh mục để xem.',
    );
    await reveal(find.byType(FilterChip).first);
    await tester.tap(find.byType(FilterChip).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.byType(CategoryChart)),
      alignment: .25,
    );
    await tester.pumpAndSettle();
    await capture('07_donut');
    await hold(8);
    await reveal(find.byType(WeeklyChart));
    debugPrint('DEMO_STEP: Biểu đồ chi tiêu tuần. Chạm ngày để xem số tiền.');
    await reveal(find.text('T4'));
    await tapText('T4');
    await Scrollable.ensureVisible(
      tester.element(find.byType(WeeklyChart)),
      alignment: .25,
    );
    await tester.pumpAndSettle();
    await capture('08_weekly');
    await hold(8);
    await tapText('Giao dịch');
    debugPrint('DEMO_STEP: Tìm kiếm, lọc và mở giao dịch để chỉnh sửa.');
    await capture('09_history');
    await hold(8);
    final first = find.text('LE MINH HOA');
    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('amount')), '210000');
    await hold(4);
    await reveal(find.byKey(const ValueKey('save')));
    await tester.tap(find.byKey(const ValueKey('save')));
    await tester.pumpAndSettle();
    await hold(4);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    await tapText('Giao diện tối');
    debugPrint(
      'DEMO_STEP: Material 3: giao diện tối và tùy chọn theo hệ thống.',
    );
    await hold(4);
    Navigator.of(tester.element(find.text('Cài đặt').last)).pop();
    await tester.pumpAndSettle();
    await capture('10_dark_history');
    await hold(8);
    await tapText('Tổng quan');
    await capture('11_dashboard_final');
    await hold(8);
    await File(p.join(screenshotDir.path, 'metrics.txt')).writeAsString(
      store.transactions
          .map((t) => '${t.reference}: ${t.ocrMilliseconds} ms')
          .join('\n'),
    );
    debugPrint('DEMO_RECORDING_END');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 20)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    for (final transaction in store.transactions.toList()) {
      await store.delete(transaction);
    }
    await repository.close();
    await deleteDatabase(dbPath);
    expect(find.byType(HomeScreen), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
