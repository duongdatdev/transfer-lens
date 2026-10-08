import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/transfer_parser.dart';
import '../services/ocr_service.dart';
import 'app_theme.dart';
import 'camera_screen.dart';
import 'review_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool busy = false;
  String status = '';
  String? error;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Nhập ảnh chuyển khoản')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Container(
              height: 156,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chuyển khoản xong.\nGhi lại trong vài chạm.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Chọn ảnh giao dịch thành công từ ứng dụng ngân hàng. Giữ rõ số tiền, ngày và thông tin người gửi/nhận.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (busy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
            ],
            if (error != null) ...[
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: busy ? null : _gallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh từ thư viện'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : _camera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Chụp ảnh giao dịch'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: busy
                  ? null
                  : () => Navigator.of(context)
                        .push(
                          MaterialPageRoute<bool>(
                            builder: (_) => const ReviewScreen(),
                          ),
                        )
                        .then((saved) {
                          if (saved == true && context.mounted) {
                            Navigator.pop(context);
                          }
                        }),
              icon: const Icon(Icons.edit_note),
              label: const Text('Nhập thủ công'),
            ),
            const SizedBox(height: 28),
            Text(
              'Thử với ảnh mẫu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Dữ liệu giả để demo. Mỗi ảnh được chạy qua ML Kit thật trên thiết bị.',
            ),
            const SizedBox(height: 12),
            ...[
              (
                'food',
                'Bữa trưa',
                '150.000 ₫ · Có gợi ý Ăn uống',
                Icons.restaurant_outlined,
              ),
              (
                'study',
                'Học phí',
                '450.000 ₫ · Có gợi ý Học tập',
                Icons.menu_book_outlined,
              ),
              (
                'unknown',
                'Chuyển tiền',
                '200.000 ₫ · Tự chọn danh mục',
                Icons.category_outlined,
              ),
              (
                'income',
                'Tiền sinh hoạt',
                '1.200.000 ₫ · Thử ghi nhận khoản thu',
                Icons.south_west_outlined,
              ),
            ].map(
              (sample) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    enabled: !busy,
                    leading: Icon(sample.$4),
                    title: Text(sample.$2),
                    subtitle: Text(sample.$3),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: busy ? null : () => _sample(sample.$1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ảnh được xử lý ngoại tuyến và chỉ lưu khi bạn xác nhận. Ứng dụng không thực hiện chuyển khoản.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _gallery() async {
    try {
      final recovered = await ImagePicker().retrieveLostData();
      final selected =
          recovered.files?.firstOrNull ??
          await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 2400,
            maxHeight: 3200,
            imageQuality: 95,
          );
      if (selected == null || !mounted) return;
      await _process(selected.path, crop: true);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Không thể mở ảnh. Hãy thử ảnh JPG/PNG khác hoặc kiểm tra quyền truy cập.',
        );
      }
    }
  }

  Future<void> _camera() async {
    final image = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const CameraScreen()));
    if (image != null && mounted) await _process(image, crop: true);
  }

  Future<void> _sample(String name) async {
    setState(() {
      busy = true;
      error = null;
      status = 'Đang mở ảnh mẫu…';
    });
    File? file;
    try {
      final bytes = await rootBundle.load('assets/samples/$name.png');
      file = File(
        p.join(
          (await getTemporaryDirectory()).path,
          'sample_${name}_${DateTime.now().microsecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      if (mounted) await _process(file.path, crop: false);
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Không thể đọc ảnh mẫu. Vui lòng thử lại.';
          busy = false;
        });
      }
    } finally {
      if (file != null && await file.exists()) await file.delete();
    }
  }

  Future<void> _process(String path, {required bool crop}) async {
    setState(() {
      busy = true;
      error = null;
      status = crop
          ? 'Khoanh vùng thông tin giao dịch…'
          : 'Đang nhận dạng trên thiết bị…';
    });
    final service = OcrService();
    try {
      if (crop) {
        final result = await ImageCropper().cropImage(
          sourcePath: path,
          maxWidth: 2400,
          maxHeight: 3200,
          compressQuality: 95,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Cắt ảnh giao dịch',
              toolbarColor: const Color(0xFF176B58),
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Cắt ảnh giao dịch'),
          ],
        );
        if (result == null) return;
        path = result.path;
      }
      if (!mounted) return;
      setState(() => status = 'Đang nhận dạng trên thiết bị…');
      final result = await service.recognize(path);
      final parsed = TransferParser().parse(result.text);
      if (!mounted) return;
      setState(() => busy = false);
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              ReviewScreen(parsed: parsed, ocr: result, sourcePath: path),
        ),
      );
      if (saved == true && mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'OCR không đọc được ảnh. Hãy chọn ảnh rõ hơn hoặc nhập thủ công.',
        );
      }
    } finally {
      await service.close();
      if (mounted) setState(() => busy = false);
    }
  }
}
