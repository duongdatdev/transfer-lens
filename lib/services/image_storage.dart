import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Uint8List _thumbnail(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image');
  return img.encodeJpg(img.copyResize(img.bakeOrientation(decoded), width: 240), quality: 75);
}

class StoredImage {
  const StoredImage(this.path, this.thumbnailPath);
  final String path;
  final String thumbnailPath;
}

class ImageStorage {
  Future<Directory> _directory() async => Directory(p.join((await getApplicationDocumentsDirectory()).path, 'transfers'))..createSync(recursive: true);

  Future<StoredImage> cache(String sourcePath) async {
    final dir = await _directory();
    final stem = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = await File(sourcePath).readAsBytes();
    final thumb = await compute(_thumbnail, bytes);
    final file = File(p.join(dir.path, '$stem${p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath)}'));
    final thumbnail = File(p.join(dir.path, '${stem}_thumb.jpg'));
    try {
      await file.writeAsBytes(bytes, flush: true);
      await thumbnail.writeAsBytes(thumb, flush: true);
      return StoredImage(file.path, thumbnail.path);
    } catch (_) {
      if (await file.exists()) await file.delete();
      if (await thumbnail.exists()) await thumbnail.delete();
      rethrow;
    }
  }

  Future<void> remove(String? path) async {
    if (path == null) return;
    final dir = await _directory();
    if (!p.isWithin(dir.path, path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
