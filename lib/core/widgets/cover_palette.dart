import 'dart:typed_data';
import 'dart:ui' as ui;

/// La couleur majoritaire hors marges blanches. L'image a déjà été réduite
/// à 24 × 24 : aucun calcul de palette pendant un geste ou une frame animée.
ui.Color? dominantCoverColor(Uint8List rgba) {
  final buckets = <int, List<int>>{};
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    if (rgba[i + 3] < 128 || (r > 225 && g > 225 && b > 225)) continue;
    final key = ((r ~/ 32) << 6) | ((g ~/ 32) << 3) | (b ~/ 32);
    final bucket = buckets.putIfAbsent(key, () => [0, 0, 0, 0]);
    bucket[0]++;
    bucket[1] += r;
    bucket[2] += g;
    bucket[3] += b;
  }
  if (buckets.isEmpty) return null;
  final winner = buckets.values.reduce((a, b) => a[0] >= b[0] ? a : b);
  return ui.Color.fromARGB(
    255,
    winner[1] ~/ winner[0],
    winner[2] ~/ winner[0],
    winner[3] ~/ winner[0],
  );
}

Future<ui.Color?> paletteFromCover(ui.Image image) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    image,
    ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    const ui.Rect.fromLTWH(0, 0, 24, 24),
    ui.Paint(),
  );
  final picture = recorder.endRecording();
  final thumbnail = await picture.toImage(24, 24);
  picture.dispose();
  try {
    final data = await thumbnail.toByteData();
    return data == null ? null : dominantCoverColor(data.buffer.asUint8List());
  } finally {
    thumbnail.dispose();
  }
}
