import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  const OcrResult(this.text, this.milliseconds);
  final String text;
  final int milliseconds;
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  Future<OcrResult> recognize(String imagePath) async {
    final watch = Stopwatch()..start();
    final recognized = await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    watch.stop();
    // Sort visual rows because banking screenshots may contain separate label/value blocks.
    final lines = recognized.blocks.expand((b) => b.lines).toList()..sort((a, b) {
      final dy = a.boundingBox.top - b.boundingBox.top;
      if (dy.abs() < 10) return a.boundingBox.left.compareTo(b.boundingBox.left);
      return dy.compareTo(0);
    });
    return OcrResult(lines.map((line) => line.text).join('\n'), watch.elapsedMilliseconds);
  }
  Future<void> close() => _recognizer.close();
}
