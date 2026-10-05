// Dokunmatik imza alanı (kargo teslim kanıtı, TEST_RAPORU 2.3).
//
// Harici paket kullanılmaz: çizgiler CustomPainter ile çizilir, PNG'ye
// dart:ui PictureRecorder ile dönüştürülür.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SignatureController extends ChangeNotifier {
  final List<List<Offset>> strokes = [];

  bool get isEmpty => strokes.every((s) => s.length < 2);

  void start(Offset p) {
    strokes.add([p]);
    notifyListeners();
  }

  void extend(Offset p) {
    if (strokes.isEmpty) return;
    strokes.last.add(p);
    notifyListeners();
  }

  void clear() {
    strokes.clear();
    notifyListeners();
  }

  /// İmzayı beyaz zeminli PNG olarak verir; boşsa null.
  Future<Uint8List?> toPng(Size size) async {
    if (isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    SignaturePainter(strokes).paint(canvas, size);
    final image = await recorder.endRecording().toImage(size.width.ceil(), size.height.ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}

class SignaturePainter extends CustomPainter {
  SignaturePainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}

class SignaturePad extends StatelessWidget {
  const SignaturePad({super.key, required this.controller, this.height = 180});
  final SignatureController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
      child: GestureDetector(
        onPanStart: (d) => controller.start(d.localPosition),
        onPanUpdate: (d) => controller.extend(d.localPosition),
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) => CustomPaint(painter: SignaturePainter(controller.strokes), size: Size.infinite),
        ),
      ),
    );
  }
}

/// İmza ister; imzalanırsa PNG baytlarını, "imzasız" seçilirse boş listeyi, vazgeçilirse null döner.
Future<Uint8List?> askSignature(BuildContext context, {String title = 'Teslim alan imzası'}) async {
  final ctrl = SignatureController();
  const size = Size(320, 180);
  final result = await showDialog<Uint8List>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: size.width, child: SignaturePad(controller: ctrl, height: size.height)),
      actions: [
        TextButton(onPressed: () => ctrl.clear(), child: const Text('Temizle')),
        TextButton(onPressed: () => Navigator.pop(ctx, Uint8List(0)), child: const Text('İmzasız teslim')),
        FilledButton(
          onPressed: () async {
            final png = await ctrl.toPng(size);
            if (ctx.mounted) Navigator.pop(ctx, png ?? Uint8List(0));
          },
          child: const Text('Onayla'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}
