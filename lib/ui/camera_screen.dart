import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  bool flash = false;
  bool capturing = false;
  String? error;
  int generation = 0;
  Offset? focusPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final request = ++generation;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera available');
      }
      final camera =
          cameras
              .where((c) => c.lensDirection == CameraLensDirection.back)
              .firstOrNull ??
          cameras.first;
      final next = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted || request != generation) {
        await next.dispose();
        return;
      }
      setState(() {
        controller = next;
        error = null;
        flash = false;
      });
    } on CameraException catch (exception) {
      if (mounted && request == generation) {
        setState(
          () => error = exception.code.contains('Access')
              ? 'Chưa được cấp quyền camera. Hãy cho phép trong cài đặt thiết bị hoặc nhập ảnh từ thư viện.'
              : 'Camera không khả dụng. Bạn có thể chọn ảnh từ thư viện.',
        );
      }
    } catch (_) {
      if (mounted && request == generation) {
        setState(
          () => error = 'Không thể khởi động camera. Hãy quay lại và chọn ảnh từ thư viện.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      generation++;
      final current = controller;
      controller = null;
      current?.dispose();
    } else if (state == AppLifecycleState.resumed && controller == null) {
      _initialize();
    }
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text('Chụp giao dịch'),
      actions: [
        IconButton(
          tooltip: flash ? 'Tắt đèn flash' : 'Bật đèn flash',
          onPressed: controller == null || capturing
              ? null
              : () async {
                  try {
                    await controller!.setFlashMode(
                      flash ? FlashMode.off : FlashMode.torch,
                    );
                    if (mounted) setState(() => flash = !flash);
                  } catch (_) {
                    _message('Camera này không hỗ trợ đèn flash.');
                  }
                },
          icon: Icon(flash ? Icons.flash_on : Icons.flash_off),
        ),
      ],
    ),
    body: SafeArea(
      child: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            )
          : controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => GestureDetector(
                      onTapDown: (details) async {
                        final current = controller;
                        if (current == null || capturing) return;
                        final point = Offset(
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0, 1),
                          (details.localPosition.dy / constraints.maxHeight)
                              .clamp(0, 1),
                        );
                        setState(() => focusPoint = details.localPosition);
                        try {
                          await current.setFocusPoint(point);
                          await current.setExposurePoint(point);
                        } catch (_) {
                          _message('Camera này sử dụng lấy nét tự động.');
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: controller!.value.aspectRatio > 1
                                  ? 1 / controller!.value.aspectRatio
                                  : controller!.value.aspectRatio,
                              child: CameraPreview(controller!),
                            ),
                          ),
                          const IgnorePointer(
                            child: CustomPaint(painter: FrameOverlay()),
                          ),
                          if (focusPoint != null)
                            Positioned(
                              left: focusPoint!.dx - 24,
                              top: focusPoint!.dy - 24,
                              child: IgnorePointer(
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chạm để lấy nét. Cắt ảnh ở bước tiếp theo.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: FilledButton.icon(
                    onPressed: capturing ? null : _capture,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(capturing ? 'Đang chụp…' : 'Chụp ảnh'),
                  ),
                ),
              ],
            ),
    ),
  );

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _capture() async {
    setState(() => capturing = true);
    try {
      final image = await controller!.takePicture();
      if (mounted) Navigator.pop(context, image.path);
    } catch (_) {
      _message('Không thể chụp ảnh. Hãy thử lại.');
      if (mounted) setState(() => capturing = false);
    }
  }
}

class FrameOverlay extends CustomPainter {
  const FrameOverlay();
  @override
  void paint(Canvas canvas, Size size) {
    final frame = Rect.fromLTWH(
      size.width * .08,
      size.height * .12,
      size.width * .84,
      size.height * .76,
    );
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .45));
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(20)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant FrameOverlay oldDelegate) => false;
}
