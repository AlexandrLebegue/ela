import '../services/moderation_service.dart';
import 'fake_delay.dart';

/// Modération simulée : bloque les mots injurieux / spam / pub déguisée.
/// En phase 2, l'IA (Cloud Function) remplace cette liste.
class FakeModerationService implements ModerationService {
  static final List<RegExp> _patterns = [
    RegExp(r'\b(merde|putain|connard|salope|crétin|bordel|encule|taré|taro)\b',
        caseSensitive: false),
    RegExp(r'(www\.\S+|https?://\S+)', caseSensitive: false),
    RegExp(r'(revente|pas cher|clic ici|lién|affiliation)\s', caseSensitive: false),
  ];

  @override
  Future<bool> isAllowed(String text) async {
    await fakeDelay(min: const Duration(milliseconds: 150),
        max: const Duration(milliseconds: 400));
    final clean = text.trim();
    if (clean.isEmpty || clean.length > 4000) return false;
    for (final p in _patterns) {
      if (p.hasMatch(clean)) return false;
    }
    return true;
  }
}
