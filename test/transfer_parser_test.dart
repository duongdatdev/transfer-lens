import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_lens/domain/transaction.dart';
import 'package:transfer_lens/domain/transfer_parser.dart';

void main() {
  final parser = TransferParser();
  group('VND amounts', () {
    for (final value in [
      '150,000 VND',
      '150.000 đ',
      '150 000',
      '+150000',
      '150,000.00',
    ]) {
      test(
        'accepts $value',
        () => expect(TransferParser.parseVnd(value), 150000),
      );
    }
    for (final value in [
      '0',
      'abc',
      '12.34',
      '150.00',
      '1,234.567',
      '1000000000000',
    ]) {
      test(
        'rejects $value',
        () => expect(TransferParser.parseVnd(value), isNull),
      );
    }
  });

  test(
    'extracts a Vietnamese transfer without confusing account, balance or fee',
    () {
      final result = parser.parse('''Chuyển khoản thành công
      Số tiền: 150.000 đ
      Người gửi
      NGUYEN VAN AN
      Người nhận: TRAN THI BINH
      Số tài khoản: 1234567890123
      Nội dung: thanh toan an trua
      Ngày giao dịch: 07/10/2026 12:30
      Phí: 2.000 VND
      Số dư: 9.000.000 VND
      Mã giao dịch: FT26123456789''');
      expect(result.amount, 150000);
      expect(result.sender, 'NGUYEN VAN AN');
      expect(result.recipient, 'TRAN THI BINH');
      expect(result.description, 'thanh toan an trua');
      expect(result.reference, 'FT26123456789');
      expect(result.date, DateTime(2026, 10, 7));
      expect(result.category, ExpenseCategory.food);
      expect(result.successDetected, isTrue);
      expect(result.warnings, isEmpty);
    },
  );

  test('supports English labels and split amount lines', () {
    final result = parser.parse('''Transfer successful
      Transfer amount
      250,000 VND
      From: ALICE
      To: BOB
      Description: tuition
      Date: 07/10/2026
      Reference: TEST-123''');
    expect(result.amount, 250000);
    expect(result.category, ExpenseCategory.study);
    expect(result.sender, 'ALICE');
    expect(result.recipient, 'BOB');
  });

  test('does not guess from account numbers or fee-only screenshots', () {
    expect(
      parser
          .parse('Số tài khoản: 123456789\nPhí: 2000 VND\nSố dư: 150000 VND')
          .amount,
      isNull,
    );
  });
  test('rejects ambiguous unlabeled amounts', () {
    expect(parser.parse('150.000 VND\n250.000 VND').amount, isNull);
  });
  test('never extracts a partial value from malformed monetary tokens', () {
    for (final value in ['150.00 VND', '100,50 VND', '1,234.567 VND']) {
      expect(parser.parse('Số tiền: $value').amount, isNull);
    }
  });
  test('prioritizes a labeled amount over a larger currency amount', () {
    expect(parser.parse('9.000.000 VND\nSố tiền: 150.000 VND').amount, 150000);
  });
  test('rejects invalid dates and ambiguous dates', () {
    expect(parser.parse('31/02/2026').date, isNull);
    expect(parser.parse('07/10/2026\n08/10/2026').date, isNull);
    expect(parser.parse('29/02/2024').date, DateTime(2024, 2, 29));
  });
  test('never treats a failed or pending transfer as successful', () {
    for (final text in [
      'không thành công',
      'Chuyển khoản thất bại',
      'unsuccessful transfer',
      'pending',
    ]) {
      final result = parser.parse(text);
      expect(result.successDetected, isFalse);
      expect(result.failureDetected, isTrue);
    }
  });
  test(
    'classifies only unambiguous description keywords with word boundaries',
    () {
      expect(
        parser.suggestCategory('học phí tháng 10').$1,
        ExpenseCategory.study,
      );
      expect(parser.suggestCategory('Grab đi học').$1, ExpenseCategory.travel);
      expect(parser.suggestCategory('Mua tai nghe').$1, ExpenseCategory.gear);
      expect(
        parser.suggestCategory('Vé xem phim').$1,
        ExpenseCategory.entertainment,
      );
      expect(parser.suggestCategory('chuyen tien').$1, isNull);
      expect(parser.suggestCategory('hoan tien an trua va sach').$1, isNull);
      expect(parser.suggestCategory('company').$1, isNull);
      expect(
        parser.parse('Người nhận: GRAB\nNội dung: Chuyen tien').category,
        isNull,
      );
    },
  );
  test('retains multiline description but stops at the next field', () {
    final result = parser.parse(
      'Nội dung\nthanh toan\nhoc phi\nNgày giao dịch\n07/10/2026',
    );
    expect(result.description, 'thanh toan hoc phi');
    expect(result.category, ExpenseCategory.study);
  });
  test('empty OCR remains safely editable', () {
    final result = parser.parse('');
    expect(result.amount, isNull);
    expect(result.category, isNull);
    expect(result.warnings.length, 3);
  });
}
