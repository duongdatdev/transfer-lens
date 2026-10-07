import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/transaction.dart';

abstract class TransactionRepository {
  Future<List<TransferTransaction>> all();
  Future<int> save(TransferTransaction transaction);
  Future<void> delete(int id);
  Future<void> close();
}

class SqliteTransactionRepository implements TransactionRepository {
  SqliteTransactionRepository(this.database);
  final Database database;

  static Future<SqliteTransactionRepository> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), 'transfer_lens.db');
    final db = await dbFactory.openDatabase(dbPath, options: OpenDatabaseOptions(version: 1, onCreate: (db, _) async {
      await db.execute('''CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL CHECK(amount > 0 AND amount <= 999999999999),
        date TEXT NOT NULL,
        direction TEXT NOT NULL CHECK(direction IN ('expense', 'income')),
        category TEXT NOT NULL,
        sender TEXT NOT NULL, recipient TEXT NOT NULL,
        description TEXT NOT NULL, reference TEXT NOT NULL, raw_text TEXT NOT NULL,
        image_path TEXT, thumbnail_path TEXT, ocr_ms INTEGER
      )''');
      await db.execute('CREATE INDEX transactions_date ON transactions(date DESC)');
      await db.execute('CREATE INDEX transactions_reference ON transactions(reference)');
    }));
    return SqliteTransactionRepository(db);
  }

  @override
  Future<List<TransferTransaction>> all() async => (await database.query('transactions', orderBy: 'date DESC, id DESC')).map(TransferTransaction.fromMap).toList();

  @override
  Future<int> save(TransferTransaction transaction) async {
    if (transaction.id == null) return database.insert('transactions', transaction.toMap());
    final count = await database.update('transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
    if (count != 1) throw StateError('Transaction no longer exists');
    return transaction.id!;
  }

  @override
  Future<void> delete(int id) async { await database.delete('transactions', where: 'id = ?', whereArgs: [id]); }
  @override
  Future<void> close() => database.close();
}
