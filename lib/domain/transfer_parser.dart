import 'transaction.dart';

String normalizeText(String text) {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  var result = text.toLowerCase();
  groups.forEach((letter, accents) {
    for (final accent in accents.split('')) {
      result = result.replaceAll(accent, letter);
    }
  });
  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class ParsedTransfer {
  const ParsedTransfer({
    this.amount,
    this.date,
    this.sender = '',
    this.recipient = '',
    this.description = '',
    this.reference = '',
    this.category,
    this.categoryReason,
    this.successDetected = false,
    this.failureDetected = false,
    this.warnings = const [],
  });
  final int? amount;
  final DateTime? date;
  final String sender;
  final String recipient;
  final String description;
  final String reference;
  final ExpenseCategory? category;
  final String? categoryReason;
  final bool successDetected;
  final bool failureDetected;
  final List<String> warnings;
}

class TransferParser {
  static const _amountLabels = [
    'so tien chuyen',
    'so tien giao dich',
    'transfer amount',
    'transaction amount',
    'so tien',
    'amount',
  ];
  static const _senderLabels = [
    'ten nguoi chuyen',
    'ten nguoi gui',
    'nguoi chuyen',
    'nguoi gui',
    'nguoi thanh toan',
    'sender',
    'from',
  ];
  static const _recipientLabels = [
    'ten nguoi nhan',
    'nguoi thu huong',
    'ten thu huong',
    'nguoi nhan',
    'recipient',
    'beneficiary',
    'to',
  ];
  static const _descriptionLabels = [
    'noi dung chuyen khoan',
    'noi dung giao dich',
    'noi dung',
    'loi nhan',
    'description',
    'message',
    'remark',
  ];
  static const _referenceLabels = [
    'ma giao dich',
    'ma tham chieu',
    'transaction id',
    'reference',
    'transaction no',
  ];
  static const _dateLabels = [
    'thoi gian giao dich',
    'ngay giao dich',
    'thoi gian',
    'ngay',
    'date',
    'time',
  ];
  static const _excludeLabels = [
    'so du',
    'balance',
    'phi',
    'fee',
    'tai khoan',
    'account',
    'ma giao dich',
    'reference',
    'transaction id',
  ];
  static final _money = RegExp(
    r'(?<![\w.,])[-+]?\s*(\d(?:[\d.,\s]*\d)?)(?:\s*)(VND|VNĐ|đ|₫|dong)?(?![\d.,])',
    caseSensitive: false,
  );

  ParsedTransfer parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((s) => s.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final warnings = <String>[];
    final candidates = <({int amount, int score})>[];
    for (var i = 0; i < lines.length; i++) {
      final normalized = normalizeText(lines[i]);
      if (_excludeLabels.any((label) => normalized.contains(label))) continue;
      if (_datePattern.hasMatch(lines[i]) ||
          RegExp(r'\d{1,2}:\d{2}').hasMatch(lines[i])) {
        continue;
      }
      final labelled = _amountLabels.any(
        (label) => normalized.startsWith(label),
      );
      final previousLabel =
          i > 0 &&
          _amountLabels.any(
            (label) => normalizeText(lines[i - 1]).startsWith(label),
          );
      for (final match in _money.allMatches(lines[i])) {
        final amount = parseVnd(match.group(1)!);
        final currency = match.group(2) != null;
        final grouped = RegExp(r'[.,\s]').hasMatch(match.group(1)!);
        if (amount == null || (!labelled && !previousLabel && !currency)) {
          continue;
        }
        if (!labelled &&
            !previousLabel &&
            !grouped &&
            match.group(1)!.length > 9) {
          continue;
        }
        candidates.add((
          amount: amount,
          score:
              (labelled || previousLabel ? 100 : 0) +
              (currency ? 30 : 0) +
              (grouped ? 5 : 0),
        ));
      }
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    int? amount;
    if (candidates.isNotEmpty) {
      final best = candidates
          .where((c) => c.score == candidates.first.score)
          .map((c) => c.amount)
          .toSet();
      if (best.length == 1) {
        amount = best.single;
      } else {
        warnings.add(
          'Có nhiều số tiền có độ tin cậy tương đương. Hãy nhập đúng số tiền giao dịch.',
        );
      }
    }
    if (amount == null) {
      warnings.add(
        'Chưa xác định được số tiền. Vui lòng kiểm tra ảnh và nhập thủ công.',
      );
    }
    final date = _extractDate(lines);
    if (date == null) {
      warnings.add('Chưa đọc được ngày hợp lệ. Vui lòng chọn ngày giao dịch.');
    }
    final description = _extractField(
      lines,
      _descriptionLabels,
      multiline: true,
    );
    final suggestion = suggestCategory(description);
    final normalized = normalizeText(rawText);
    final failure = RegExp(
      r'that bai|khong thanh cong|failed|unsuccessful|dang xu ly|pending',
    ).hasMatch(normalized);
    final success =
        !failure &&
        RegExp(r'thanh cong|successful|completed|success').hasMatch(normalized);
    if (!success) {
      warnings.add(
        failure
            ? 'Ảnh có trạng thái thất bại hoặc đang xử lý. Chỉ lưu nếu bạn đã xác minh giao dịch thực sự hoàn tất.'
            : 'Không đọc được trạng thái thành công. Hãy xác minh giao dịch trước khi lưu.',
      );
    }
    return ParsedTransfer(
      amount: amount,
      date: date,
      sender: _extractField(lines, _senderLabels),
      recipient: _extractField(lines, _recipientLabels),
      description: description,
      reference: _extractField(lines, _referenceLabels),
      category: suggestion.$1,
      categoryReason: suggestion.$2,
      successDetected: success,
      failureDetected: failure,
      warnings: warnings,
    );
  }

  // VND is stored as integer units; decimal fractions and malformed grouping are rejected.
  static int? parseVnd(String text) {
    var value = text
        .trim()
        .replaceAll(
          RegExp(r'\s*(VND|VNĐ|đ|₫|dong)\s*$', caseSensitive: false),
          '',
        )
        .trim()
        .replaceFirst(RegExp(r'^[+-]\s*'), '');
    if (RegExp(r'^\d{1,3}(?:[.,]\d{3})+[.,]00$').hasMatch(value)) {
      value = value.substring(0, value.length - 3);
    }
    if (!RegExp(
      r'^(?:\d+|\d{1,3}(?:\.\d{3})+|\d{1,3}(?:,\d{3})+|\d{1,3}(?:\s\d{3})+)$',
    ).hasMatch(value)) {
      return null;
    }
    final amount = int.tryParse(value.replaceAll(RegExp(r'[.,\s]'), ''));
    return amount != null && amount > 0 && amount <= 999999999999
        ? amount
        : null;
  }

  static final _datePattern = RegExp(
    r'(?<!\d)(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})(?!\d)',
  );
  DateTime? _extractDate(List<String> lines) {
    final values = <DateTime>{};
    for (final line in lines) {
      for (final match in _datePattern.allMatches(line)) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        final date = DateTime(year, month, day);
        if (year < 2000 ||
            year > 2100 ||
            date.day != day ||
            date.month != month) {
          continue;
        }
        values.add(date);
      }
    }
    return values.length == 1 ? values.single : null;
  }

  static const _allLabels = [
    ..._amountLabels,
    ..._senderLabels,
    ..._recipientLabels,
    ..._descriptionLabels,
    ..._referenceLabels,
    ..._dateLabels,
    ..._excludeLabels,
    'ngan hang',
    'bank',
    'trang thai',
    'status',
  ];

  String _extractField(
    List<String> lines,
    List<String> labels, {
    bool multiline = false,
  }) {
    for (var i = 0; i < lines.length; i++) {
      final normalized = normalizeText(lines[i]);
      for (final label in labels) {
        if (!normalized.startsWith(label) ||
            (normalized.length > label.length &&
                !RegExp(r'[:\s-]').hasMatch(normalized[label.length]))) {
          continue;
        }
        var value = lines[i]
            .substring(label.length)
            .replaceFirst(RegExp(r'^\s*[:\-]?\s*'), '')
            .trim();
        final parts = <String>[if (value.isNotEmpty) value];
        for (
          var j = i + 1;
          j < lines.length && j <= i + (multiline ? 3 : 1);
          j++
        ) {
          if (parts.isNotEmpty && !multiline) break;
          final next = normalizeText(lines[j]);
          if (_allLabels.any((l) => next.startsWith(l)) ||
              RegExp(r'thanh cong|successful|completed').hasMatch(next)) {
            break;
          }
          parts.add(lines[j]);
        }
        return parts.join(' ').trim();
      }
    }
    return '';
  }

  (ExpenseCategory?, String?) suggestCategory(String description) {
    final text =
        ' ${normalizeText(description).replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')} ';
    const keywords = {
      ExpenseCategory.food: [
        'an trua',
        'an toi',
        'an sang',
        'com',
        'cafe',
        'coffee',
        'tra sua',
        'bun',
        'pho',
        'food',
        'lunch',
        'dinner',
      ],
      ExpenseCategory.study: [
        'hoc phi',
        'sach',
        'giao trinh',
        'khoa hoc',
        'in tai lieu',
        'tuition',
        'book',
        'study',
      ],
      ExpenseCategory.travel: [
        'grab',
        'taxi',
        'xang',
        've xe',
        've tau',
        'di chuyen',
        'bus',
        'travel',
      ],
      ExpenseCategory.gear: [
        'mua sam',
        'quan ao',
        'tai nghe',
        'ban phim',
        'dien thoai',
        'laptop',
        'shopping',
        'gear',
      ],
      ExpenseCategory.entertainment: [
        'xem phim',
        've phim',
        'cinema',
        'game',
        'netflix',
        'spotify',
        'giai tri',
        'movie',
      ],
    };
    final matches = <ExpenseCategory, String>{};
    keywords.forEach((category, words) {
      for (final word in words) {
        if (text.contains(' $word ')) {
          matches[category] = word;
          break;
        }
      }
    });
    if (matches.length != 1) return (null, null);
    return (
      matches.keys.single,
      'Từ khóa trong nội dung: "${matches.values.single}"',
    );
  }
}
