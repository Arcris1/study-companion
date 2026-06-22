// Generates the Study Companion app icon assets from code (no design asset
// needed), then `dart run flutter_launcher_icons` turns them into all the
// platform icon sizes.
//
//   dart run tool/generate_icon.dart
//
// Produces (1024x1024):
//   assets/icon/app_icon.png     full icon  (gradient + book) — iOS + legacy
//   assets/icon/app_icon_bg.png  gradient only               — Android adaptive bg
//   assets/icon/app_icon_fg.png  transparent + book          — Android adaptive fg
import 'dart:io';
import 'package:image/image.dart' as img;

const int size = 1024;

// Brand gradient: violet #7C3AED -> indigo #4F46E5 (matches AppColors).
const _start = [0x7C, 0x3A, 0xED];
const _end = [0x4F, 0x46, 0xE5];

int _lerp(int a, int b, double t) => (a + (b - a) * t).round();

void _fillGradient(img.Image image) {
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final t = (x + y) / (2 * (size - 1));
      image.setPixelRgba(
        x,
        y,
        _lerp(_start[0], _end[0], t),
        _lerp(_start[1], _end[1], t),
        _lerp(_start[2], _end[2], t),
        255,
      );
    }
  }
}

/// Draws a clean white open book centered on [image].
void _drawBook(img.Image image) {
  final white = img.ColorRgba8(255, 255, 255, 255);
  final cx = size / 2;
  final pageW = size * 0.235;
  final gap = size * 0.020;
  final topInner = size * 0.350;
  final topOuter = size * 0.392;
  final botInner = size * 0.608;
  final botOuter = size * 0.650;

  // Left page.
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx - gap, topInner),
      img.Point(cx - gap - pageW, topOuter),
      img.Point(cx - gap - pageW, botOuter),
      img.Point(cx - gap, botInner),
    ],
    color: white,
  );
  // Right page (mirror).
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx + gap, topInner),
      img.Point(cx + gap + pageW, topOuter),
      img.Point(cx + gap + pageW, botOuter),
      img.Point(cx + gap, botInner),
    ],
    color: white,
  );

  // Faint "text" lines on each page (gradient-tinted) to read as pages.
  final line = img.ColorRgba8(0x7C, 0x3A, 0xED, 90);
  for (var i = 0; i < 3; i++) {
    final dy = size * (0.420 + i * 0.060);
    img.drawLine(image,
        x1: (cx - gap - pageW * 0.82).round(),
        y1: (dy + size * 0.030).round(),
        x2: (cx - gap - pageW * 0.12).round(),
        y2: dy.round(),
        color: line,
        thickness: 8);
    img.drawLine(image,
        x1: (cx + gap + pageW * 0.12).round(),
        y1: dy.round(),
        x2: (cx + gap + pageW * 0.82).round(),
        y2: (dy + size * 0.030).round(),
        color: line,
        thickness: 8);
  }
}

void _write(String path, img.Image image) {
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path');
}

void main() {
  // Full icon: gradient + book.
  final full = img.Image(width: size, height: size, numChannels: 4);
  _fillGradient(full);
  _drawBook(full);
  _write('assets/icon/app_icon.png', full);

  // Adaptive background: gradient only.
  final bg = img.Image(width: size, height: size, numChannels: 4);
  _fillGradient(bg);
  _write('assets/icon/app_icon_bg.png', bg);

  // Adaptive foreground: transparent + book (kept within the safe zone).
  final fg = img.Image(width: size, height: size, numChannels: 4);
  // leave fully transparent
  _drawBook(fg);
  _write('assets/icon/app_icon_fg.png', fg);
}
