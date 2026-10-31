// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps, curly_braces_in_flow_control_structures
// Génère l'icône « Ela » (mipmaps mdpi→xxxhdpi) en pur Dart :
// PNG RGBA encodés à la main (zlib « stored », sans dépendance).
//
//   dart run tools/gen_launcher_icon.dart
//
// Icône : carré papier aux coins arrondis, reliure bordeaux, livre ouvert.

import 'dart:io';
import 'dart:typed_data';

const _paper = [248, 244, 235, 255];
const _gold = [112, 59, 67, 255];
const _page = [255, 252, 245, 255];

void main() {
  final targets = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };
  targets.forEach((path, size) {
    final bytes = encodePng(_render(size), size, size);
    File(path).writeAsBytesSync(bytes);
    print('→ $path (${size}×${size}, ${bytes.length} o)');
  });
}

/// Rendu 2×2 supersamplé : fond papier arrondi, reliure bordeaux, livre ouvert.
Uint8List _render(int size) {
  final ss = 2;
  final n = size * ss;
  final buf = Uint8List(n * n * 4);
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final px = (x + 0.5) / ss;
      final py = (y + 0.5) / ss;
      final c = _pixel(px / size, py / size);
      final o = (y * n + x) * 4;
      buf[o] = c[0];
      buf[o + 1] = c[1];
      buf[o + 2] = c[2];
      buf[o + 3] = c[3];
    }
  }
  // Sous-échantillonnage : moyenne des 4 pixels du bloc.
  final out = Uint8List(size * size * 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final r = [0, 0, 0, 0];
      for (var dy = 0; dy < ss; dy++) {
        for (var dx = 0; dx < ss; dx++) {
          final o = ((y * ss + dy) * n + (x * ss + dx)) * 4;
          for (var i = 0; i < 4; i++) {
            r[i] += buf[o + i];
          }
        }
      }
      final o = (y * size + x) * 4;
      for (var i = 0; i < 4; i++) {
        out[o + i] = r[i] ~/ (ss * ss);
      }
    }
  }
  return out;
}

/// u, v ∈ [0,1] → RGBA.
List<int> _pixel(double u, double v) {
  // Carré arrondi : coins de rayon 0.20.
  final r = 0.20;
  double dx = u;
  double dy = v;
  if (u < r) dx = r - u; else if (u > 1 - r) dx = u - (1 - r); else dx = 0;
  if (v < r) dy = r - v; else if (v > 1 - r) dy = v - (1 - r); else dy = 0;
  if (dx * dx + dy * dy > r * r && (u < r || u > 1 - r || v < r || v > 1 - r)) {
    return [0, 0, 0, 0];
  }

  final cx = u - 0.5;
  final cy = v - 0.5;

  // Livre ouvert (dedans du disque) : 2 pages + reliure dorée.
  // (mêmes proportions que le vector ic_ela_monogram.xml, viewport 108.)
  if (cy.abs() <= 14.8 / 108 && cx.abs() <= 17 / 108) {
    if (cx.abs() <= 2 / 108) return _gold;
    return _page;
  }
  // Disque doré.
  if (cx * cx + cy * cy <= (30 / 108) * (30 / 108)) return _gold;
  return _paper;
}

// ---------- Encodage PNG (zlib « stored », pas de compression) ----------

final _crcTable = List<int>.generate(256, (i) {
  var c = i;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

int _adler32(List<int> data) {
  var a = 1;
  var b = 0;
  for (final x in data) {
    a = (a + x) % 65521;
    b = (b + a) % 65521;
  }
  return (b << 16) | a;
}

Uint8List _zlibStored(List<int> raw) {
  final out = BytesBuilder();
  out.addByte(0x78);
  out.addByte(0x01); // CMF/FLG : deflate, aucun dictionnaire.
  final max = 65535;
  var pos = 0;
  while (pos < raw.length) {
    final len = raw.length - pos > max ? max : raw.length - pos;
    final final_ = pos + len >= raw.length ? 1 : 0;
    out.addByte(final_); // BFINAL, BTYPE=00 (stored)
    final l = len & 0xFFFF;
    out.addByte(l & 0xFF);
    out.addByte((l >> 8) & 0xFF);
    final n = (~l) & 0xFFFF;
    out.addByte(n & 0xFF);
    out.addByte((n >> 8) & 0xFF);
    out.add(raw.sublist(pos, pos + len));
    pos += len;
  }
  final a = _adler32(raw);
  out.addByte(((a >> 24) & 0xFF));
  out.addByte(((a >> 16) & 0xFF));
  out.addByte(((a >> 8) & 0xFF));
  out.addByte(a & 0xFF);
  return out.toBytes();
}

Uint8List _chunk(String type, List<int> data) {
  final out = BytesBuilder();
  final len = data.length;
  out.addByte((len >> 24) & 0xFF);
  out.addByte((len >> 16) & 0xFF);
  out.addByte((len >> 8) & 0xFF);
  out.addByte(len & 0xFF);
  final typeBytes = type.codeUnits;
  out.add(typeBytes);
  out.add(data);
  final crc = _crc32([...typeBytes, ...data]);
  out.addByte((crc >> 24) & 0xFF);
  out.addByte((crc >> 16) & 0xFF);
  out.addByte((crc >> 8) & 0xFF);
  out.addByte(crc & 0xFF);
  return out.toBytes();
}

Uint8List encodePng(List<int> rgba, int width, int height) {
  final ihdr = <int>[
    (width >> 24) & 0xFF, (width >> 16) & 0xFF, (width >> 8) & 0xFF,
    width & 0xFF,
    (height >> 24) & 0xFF, (height >> 16) & 0xFF, (height >> 8) & 0xFF,
    height & 0xFF,
    8, // profondeur
    6, // couleur : RGBA
    0, 0, 0,
  ];
  // Chaque ligne précédée de son octet de filtre (0 = none).
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    raw.add(rgba.sublist(y * width * 4, (y + 1) * width * 4));
  }
  final out = BytesBuilder();
  out.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  out.add(_chunk('IHDR', ihdr));
  out.add(_chunk('IDAT', _zlibStored(raw.toBytes())));
  out.add(_chunk('IEND', []));
  return out.toBytes();
}
