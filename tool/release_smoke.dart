import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:transfer_lens/domain/transaction.dart';
import 'package:transfer_lens/domain/transfer_parser.dart';
import 'package:transfer_lens/services/ocr_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final service = OcrService();
  File? source;
  try {
    final bytes = await rootBundle.load('assets/samples/food.png');
    source = File(
      p.join((await getTemporaryDirectory()).path, 'release_smoke.png'),
    );
    await source.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    final result = await service.recognize(source.path);
    final parsed = TransferParser().parse(result.text);
    if (parsed.amount != 150000 ||
        parsed.category != ExpenseCategory.food ||
        !parsed.successDetected) {
      throw StateError('Release OCR/parser validation failed');
    }
    debugPrint('TRANSFERLENS_RELEASE_OCR_PASS: ${result.milliseconds} ms');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Release OCR validation passed')),
        ),
      ),
    );
  } catch (error) {
    debugPrint('TRANSFERLENS_RELEASE_OCR_FAIL: $error');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Release OCR validation failed')),
        ),
      ),
    );
  } finally {
    await service.close();
    if (source != null && await source.exists()) await source.delete();
  }
}
