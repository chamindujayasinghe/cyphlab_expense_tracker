// Renders the app's launcher icon to PNG files in assets/icon/.
//
// Run with:  flutter test tool/generate_icon_test.dart
// then:      dart run flutter_launcher_icons
//
// Kept outside test/ so it doesn't run with the normal test suite.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;
const _teal = Color(0xFF0F766E);
const _tealDark = Color(0xFF115E59);
const _mint = Color(0xFF99F6E4);

void main() {
  testWidgets('generate launcher icon PNGs', (tester) async {
    await tester.runAsync(() async {
      Directory('assets/icon').createSync(recursive: true);

      // Full icon: teal background with the glyph (legacy Android, web,
      // Windows).
      await _writePng('assets/icon/icon.png', (canvas) {
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, _size, _size),
          Paint()..color = _teal,
        );
        _drawGlyph(canvas, scale: _size * 0.78);
      });

      // Adaptive icon foreground: transparent, glyph kept inside the central
      // safe zone because launchers crop adaptive icons to various shapes.
      await _writePng('assets/icon/icon_foreground.png', (canvas) {
        _drawGlyph(canvas, scale: _size * 0.5);
      });
    });
  });
}

/// A wallet with a card tucked behind it, centered on the canvas.
/// Coordinates are fractions of [scale].
void _drawGlyph(Canvas canvas, {required double scale}) {
  const center = Offset(_size / 2, _size / 2);
  Offset at(double x, double y) => center + Offset(x * scale, y * scale);

  // Card peeking out above the wallet, slightly tilted.
  canvas.save();
  canvas.translate(at(-0.02, -0.17).dx, at(-0.02, -0.17).dy);
  canvas.rotate(-8 * math.pi / 180);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 0.46 * scale, height: 0.24 * scale),
      Radius.circular(0.04 * scale),
    ),
    Paint()..color = _mint,
  );
  canvas.restore();

  // Wallet body.
  final body = Rect.fromCenter(
    center: at(0, 0.06),
    width: 0.62 * scale,
    height: 0.44 * scale,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(body, Radius.circular(0.08 * scale)),
    Paint()..color = Colors.white,
  );

  // Clasp on the right edge with a button.
  final clasp = Rect.fromLTWH(
    body.right - 0.2 * scale,
    body.center.dy - 0.085 * scale,
    0.22 * scale,
    0.17 * scale,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(clasp, Radius.circular(0.05 * scale)),
    Paint()..color = _tealDark,
  );
  canvas.drawCircle(
    Offset(clasp.left + 0.08 * scale, clasp.center.dy),
    0.03 * scale,
    Paint()..color = Colors.white,
  );
}

Future<void> _writePng(String path, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}
