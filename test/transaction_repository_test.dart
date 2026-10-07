import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:transfer_lens/data/transaction_repository.dart';
import 'package:transfer_lens/domain/transaction.dart';

void main() {
  sqfliteFfiInit();
  test('SQLite persists, sorts, updates and deletes across reopen', () async {
    final dir = await Directory.systemTemp.createTemp('transfer_lens_test');
    final path = p.join(dir.path, 'test.db');
    var repository = await SqliteTransactionRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    TransferTransaction value({int? id, int amount = 150000}) =>
        TransferTransaction(
          id: id,
          amount: amount,
          date: DateTime(2026, 10, 7),
          direction: TransactionDirection.expense,
          category: ExpenseCategory.food,
          sender: 'AN',
          recipient: 'BINH',
          description: 'an trua',
          reference: 'TEST1',
          rawText: 'OCR text',
          imagePath: '/private/image.png',
          thumbnailPath: '/private/thumb.jpg',
          ocrMilliseconds: 120,
        );
    try {
      final id = await repository.save(value());
      await repository.close();
      repository = await SqliteTransactionRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final saved = (await repository.all()).single;
      expect(saved.id, id);
      expect(saved.amount, 150000);
      expect(saved.rawText, 'OCR text');
      expect(saved.thumbnailPath, '/private/thumb.jpg');
      expect(saved.ocrMilliseconds, 120);
      await repository.save(value(id: id, amount: 200000));
      expect((await repository.all()).single.amount, 200000);
      await repository.delete(id);
      expect(await repository.all(), isEmpty);
      await expectLater(
        repository.save(value(amount: 0)),
        throwsA(isA<DatabaseException>()),
      );
    } finally {
      await repository.close();
      await dir.delete(recursive: true);
    }
  });
}
