import 'dart:math';

/// Délais simulés (300–1500 ms) pour donner la sensation réseau.
Future<void> fakeDelay({
  Duration min = const Duration(milliseconds: 300),
  Duration max = const Duration(milliseconds: 1500),
}) {
  final ms = min.inMilliseconds +
      Random().nextInt(max.inMilliseconds - min.inMilliseconds);
  return Future<void>.delayed(Duration(milliseconds: ms));
}

/// Hash stable (FNV-1a) — déterministe entre les sessions, contrairement
/// à [String.hashCode].
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}
