import 'package:intl/intl.dart';

enum ExpenseCategory {
  food('Ăn uống'),
  study('Học tập'),
  travel('Di chuyển'),
  gear('Mua sắm'),
  entertainment('Giải trí'),
  other('Khác');

  const ExpenseCategory(this.label);
  final String label;
}

enum TransactionDirection { expense, income }

String formatMoney(int amount) =>
    '${NumberFormat.decimalPattern('vi').format(amount)} ₫';
String formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

class TransferTransaction {
  const TransferTransaction({
    this.id,
    required this.amount,
    required this.date,
    required this.direction,
    required this.category,
    this.sender = '',
    this.recipient = '',
    this.description = '',
    this.reference = '',
    this.rawText = '',
    this.imagePath,
    this.thumbnailPath,
    this.ocrMilliseconds,
  });

  final int? id;
  final int amount;
  final DateTime date;
  final TransactionDirection direction;
  final ExpenseCategory category;
  final String sender;
  final String recipient;
  final String description;
  final String reference;
  final String rawText;
  final String? imagePath;
  final String? thumbnailPath;
  final int? ocrMilliseconds;

  String get counterparty =>
      direction == TransactionDirection.expense ? recipient : sender;
  String get title => counterparty.isNotEmpty
      ? counterparty
      : (description.isNotEmpty ? description : category.label);

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'direction': direction.name,
    'category': category.name,
    'sender': sender,
    'recipient': recipient,
    'description': description,
    'reference': reference,
    'raw_text': rawText,
    'image_path': imagePath,
    'thumbnail_path': thumbnailPath,
    'ocr_ms': ocrMilliseconds,
  };

  factory TransferTransaction.fromMap(Map<String, Object?> map) =>
      TransferTransaction(
        id: map['id'] as int,
        amount: map['amount'] as int,
        date: DateTime.parse(map['date'] as String),
        direction: TransactionDirection.values.byName(
          map['direction'] as String,
        ),
        category: ExpenseCategory.values.byName(map['category'] as String),
        sender: map['sender'] as String,
        recipient: map['recipient'] as String,
        description: map['description'] as String,
        reference: map['reference'] as String,
        rawText: map['raw_text'] as String,
        imagePath: map['image_path'] as String?,
        thumbnailPath: map['thumbnail_path'] as String?,
        ocrMilliseconds: map['ocr_ms'] as int?,
      );
}
