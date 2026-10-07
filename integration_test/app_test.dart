import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:transfer_lens/data/transaction_repository.dart';
import 'package:transfer_lens/domain/transaction.dart';
import 'package:transfer_lens/domain/transfer_parser.dart';
import 'package:transfer_lens/main.dart';
import 'package:transfer_lens/services/ocr_service.dart';
import 'package:transfer_lens/state/expense_store.dart';
import 'package:transfer_lens/ui/review_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native OCR, image caching, review and persistent CRUD', (
    tester,
  ) async {
    final path = p.join(await getDatabasesPath(), 'integration_test.db');
    await deleteDatabase(path);
    var repository = await SqliteTransactionRepository.open(path: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', 'light');
    var store = ExpenseStore(repository, prefs);
    final source = File(
      p.join((await getTemporaryDirectory()).path, 'integration_sample.png'),
    );
    final bytes = await rootBundle.load('assets/samples/food.png');
    await source.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    final ocr = OcrService();
    final result = await ocr.recognize(source.path);
    await ocr.close();
    final parsed = TransferParser().parse(result.text);
    expect(parsed.amount, 150000, reason: result.text);
    expect(parsed.date, DateTime(2026, 10, 7), reason: result.text);
    expect(parsed.sender, 'NGUYEN VAN AN', reason: result.text);
    expect(parsed.recipient, 'TRAN THI BINH', reason: result.text);
    expect(parsed.category, ExpenseCategory.food, reason: result.text);
    expect(parsed.successDetected, isTrue, reason: result.text);
    debugPrint('Native OCR measured: ${result.milliseconds} ms');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: MaterialApp(
          home: ReviewScreen(
            parsed: parsed,
            ocr: result,
            sourcePath: source.path,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('amount')), '155000');
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      350,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('save')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('save')));
    await tester.pumpAndSettle();
    expect(store.transactions.single.amount, 155000);
    final saved = store.transactions.single;
    expect(await File(saved.imagePath!).exists(), isTrue);
    expect(await File(saved.thumbnailPath!).exists(), isTrue);
    expect(
      store.duplicateOf(
        TransferTransaction(
          amount: 150000,
          date: saved.date,
          direction: saved.direction,
          category: saved.category,
          reference: saved.reference,
        ),
      ),
      isNotNull,
    );
    await repository.close();
    repository = await SqliteTransactionRepository.open(path: path);
    store = ExpenseStore(repository, prefs);
    await store.load();
    expect(store.transactions.single.amount, 155000);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const TransferLensApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TransferLens'), findsOneWidget);
    await store.delete(store.transactions.single);
    expect(store.transactions, isEmpty);
    expect(await File(saved.imagePath!).exists(), isFalse);
    expect(await File(saved.thumbnailPath!).exists(), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await repository.close();
    await deleteDatabase(path);
    await source.delete();
  });
}
