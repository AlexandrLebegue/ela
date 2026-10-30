/// Formatage FR (nombres groupés par espaces, prix, dates courtes).
String formatInt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatPrice(double? value) =>
    value == null ? '' : '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day} ${d.year}';

String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

const List<String> _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// Normalisation pour la recherche : minuscules, sans accents, sans ponctuation.
String normalizeQuery(String s) {
  final map = <int, String>{
    0xE9: 'e', // é
    0xE8: 'e', // è
    0xEA: 'e', // ê
    0xEB: 'e', // ë
    0xE0: 'a', // à
    0xE2: 'a', // â
    0xE4: 'a', // ä
    0xF9: 'u', // ù
    0xFB: 'u', // û
    0xFC: 'u', // ü
    0xF4: 'o', // ô
    0xF6: 'o', // ö
    0xE7: 'c', // ç
    0xEF: 'i', // ï
    0xEE: 'i', // î
    0x153: 'œ', // œ
    0x152: 'OE', // Œ
  };
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final code in lower.codeUnits) {
    out.write(map[code] ?? String.fromCharCode(code));
  }
  return out
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .trim();
}
