import 'dart:typed_data';
import 'dart:ui' as ui;

/// Decodes an image (any format the platform supports, including HEIC on iOS)
/// and re-encodes it as PNG, downscaled so its longest side is <= [maxDim].
///
/// OpenAI's vision API rejects HEIC, so iOS gallery photos must be converted;
/// this also keeps the upload small. Throws if the bytes can't be decoded —
/// callers should fall back to the original bytes.
Future<Uint8List> toVisionPng(Uint8List input, {int maxDim = 1600}) async {
  var codec = await ui.instantiateImageCodec(input);
  var frame = await codec.getNextFrame();
  var image = frame.image;

  if (image.width > maxDim || image.height > maxDim) {
    final landscape = image.width >= image.height;
    image.dispose();
    codec = await ui.instantiateImageCodec(
      input,
      targetWidth: landscape ? maxDim : null,
      targetHeight: landscape ? null : maxDim,
    );
    frame = await codec.getNextFrame();
    image = frame.image;
  }

  final bd = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bd == null) throw Exception('Could not encode image');
  return bd.buffer.asUint8List();
}
